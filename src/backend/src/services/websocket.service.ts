/**
 * Human Tasks:
 * 1. Configure Redis cluster settings in production environment
 * 2. Set up SSL/TLS certificates for secure WebSocket connections
 * 3. Configure WebSocket authentication middleware with JWT
 * 4. Set up monitoring alerts for WebSocket connection limits
 * 5. Configure WebSocket event rate limiting in production
 */

// Third-party imports with versions
import { Server } from 'socket.io'; // ^4.7.0
import { RedisAdapter, createAdapter } from '@socket.io/redis-adapter'; // ^8.2.0
import Redis from 'ioredis'; // ^5.3.0
import { EventEmitter } from 'events'; // ^3.3.0

// Internal imports
import { WEBSOCKET_PORT, WEBSOCKET_PATH } from '../config/websocket';
import { error, info } from '../utils/logger.utils';

/**
 * Core WebSocket service implementing real-time communication features
 * Requirements: 
 * - Real-time messaging system (1.2 Scope/Backend Services)
 * - Real-time Updates (3.1 High-Level Architecture Overview)
 * - System Interactions (3.4 System Interactions)
 */
class WebSocketService {
  private io: Server;
  private eventEmitter: EventEmitter;
  private userSockets: Map<string, Set<string>>;
  private roomSubscriptions: Map<string, Set<string>>;

  constructor(server: Server) {
    this.io = server;
    this.eventEmitter = new EventEmitter();
    this.userSockets = new Map();
    this.roomSubscriptions = new Map();
  }

  /**
   * Initializes the WebSocket server with required configuration
   * Requirement: Real-time Updates (3.1 High-Level Architecture Overview)
   */
  public async initialize(): Promise<void> {
    try {
      // Configure Redis adapter for horizontal scaling
      const pubClient = new Redis({
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT || '6379'),
        retryStrategy: (times) => Math.min(times * 50, 2000)
      });

      const subClient = pubClient.duplicate();

      // Set up Redis adapter
      this.io.adapter(createAdapter(pubClient, subClient));

      // Configure WebSocket server settings
      this.io.path(WEBSOCKET_PATH);
      this.io.listen(WEBSOCKET_PORT);

      // Set up authentication middleware
      this.io.use(async (socket, next) => {
        try {
          const token = socket.handshake.auth.token;
          if (!token) {
            throw new Error('Authentication required');
          }
          // Verify token and attach user data to socket
          socket.data.userId = 'user_id_from_token';
          next();
        } catch (err) {
          next(new Error('Authentication failed'));
        }
      });

      // Initialize connection handling
      this.io.on('connection', (socket) => this.handleConnection(socket));

      info('WebSocket server initialized successfully');
    } catch (err) {
      error('Failed to initialize WebSocket server:', err);
      throw err;
    }
  }

  /**
   * Handles new WebSocket connections
   * Requirement: System Interactions (3.4 System Interactions)
   */
  private handleConnection(socket: any): void {
    try {
      const userId = socket.data.userId;

      // Add to user socket mapping
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId)?.add(socket.id);

      // Set up event handlers
      this.handleMessageEvents(socket);
      this.handleFurnitureEvents(socket);
      this.handleNotificationEvents(socket);

      // Handle disconnection
      socket.on('disconnect', () => {
        this.userSockets.get(userId)?.delete(socket.id);
        if (this.userSockets.get(userId)?.size === 0) {
          this.userSockets.delete(userId);
        }
        info(`Client disconnected: ${socket.id}`);
      });

      info(`New client connected: ${socket.id}`);
    } catch (err) {
      error('Error handling connection:', err);
      socket.disconnect(true);
    }
  }

  /**
   * Sets up handlers for message-related events
   * Requirement: Real-time messaging system (1.2 Scope/Backend Services)
   */
  private handleMessageEvents(socket: any): void {
    // Private message handler
    socket.on('private_message', async (data: { recipientId: string, content: string }) => {
      try {
        const recipientSockets = this.userSockets.get(data.recipientId);
        if (recipientSockets) {
          const messageData = {
            senderId: socket.data.userId,
            content: data.content,
            timestamp: new Date()
          };
          recipientSockets.forEach(socketId => {
            this.io.to(socketId).emit('new_message', messageData);
          });
        }
      } catch (err) {
        error('Error handling private message:', err);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // Room message handler
    socket.on('room_message', async (data: { roomId: string, content: string }) => {
      try {
        const messageData = {
          senderId: socket.data.userId,
          content: data.content,
          timestamp: new Date()
        };
        this.io.to(data.roomId).emit('room_message', messageData);
      } catch (err) {
        error('Error handling room message:', err);
        socket.emit('error', { message: 'Failed to send room message' });
      }
    });

    // Typing indicator handler
    socket.on('typing', (data: { recipientId: string, isTyping: boolean }) => {
      const recipientSockets = this.userSockets.get(data.recipientId);
      if (recipientSockets) {
        recipientSockets.forEach(socketId => {
          this.io.to(socketId).emit('typing_indicator', {
            senderId: socket.data.userId,
            isTyping: data.isTyping
          });
        });
      }
    });
  }

  /**
   * Sets up handlers for furniture-related events
   * Requirement: Real-time Updates (3.1 High-Level Architecture Overview)
   */
  private handleFurnitureEvents(socket: any): void {
    // Furniture creation handler
    socket.on('furniture_created', (data: { furniture: any }) => {
      try {
        this.broadcastToRoom('furniture', 'new_furniture', data);
      } catch (err) {
        error('Error handling furniture creation:', err);
        socket.emit('error', { message: 'Failed to broadcast furniture creation' });
      }
    });

    // Furniture update handler
    socket.on('furniture_updated', (data: { furnitureId: string, updates: any }) => {
      try {
        this.broadcastToRoom('furniture', 'furniture_update', data);
      } catch (err) {
        error('Error handling furniture update:', err);
        socket.emit('error', { message: 'Failed to broadcast furniture update' });
      }
    });

    // Furniture deletion handler
    socket.on('furniture_deleted', (data: { furnitureId: string }) => {
      try {
        this.broadcastToRoom('furniture', 'furniture_removed', data);
      } catch (err) {
        error('Error handling furniture deletion:', err);
        socket.emit('error', { message: 'Failed to broadcast furniture deletion' });
      }
    });
  }

  /**
   * Sets up handlers for notification events
   * Requirement: System Interactions (3.4 System Interactions)
   */
  private handleNotificationEvents(socket: any): void {
    // Notification subscription handler
    socket.on('subscribe_notifications', (data: { topics: string[] }) => {
      try {
        data.topics.forEach(topic => {
          socket.join(`notification:${topic}`);
          if (!this.roomSubscriptions.has(topic)) {
            this.roomSubscriptions.set(topic, new Set());
          }
          this.roomSubscriptions.get(topic)?.add(socket.id);
        });
      } catch (err) {
        error('Error handling notification subscription:', err);
        socket.emit('error', { message: 'Failed to subscribe to notifications' });
      }
    });

    // Notification unsubscribe handler
    socket.on('unsubscribe_notifications', (data: { topics: string[] }) => {
      try {
        data.topics.forEach(topic => {
          socket.leave(`notification:${topic}`);
          this.roomSubscriptions.get(topic)?.delete(socket.id);
          if (this.roomSubscriptions.get(topic)?.size === 0) {
            this.roomSubscriptions.delete(topic);
          }
        });
      } catch (err) {
        error('Error handling notification unsubscription:', err);
        socket.emit('error', { message: 'Failed to unsubscribe from notifications' });
      }
    });
  }

  /**
   * Broadcasts a message to all sockets in a room
   * Requirement: System Interactions (3.4 System Interactions)
   */
  public broadcastToRoom(room: string, event: string, data: any): void {
    try {
      this.io.to(room).emit(event, {
        ...data,
        timestamp: new Date()
      });
      info(`Broadcast to room ${room}: ${event}`);
    } catch (err) {
      error('Error broadcasting to room:', err);
      throw err;
    }
  }

  /**
   * Sends a message to a specific user
   * Requirement: Real-time messaging system (1.2 Scope/Backend Services)
   */
  public sendToUser(userId: string, event: string, data: any): void {
    try {
      const userSockets = this.userSockets.get(userId);
      if (userSockets) {
        const messageData = {
          ...data,
          timestamp: new Date()
        };
        userSockets.forEach(socketId => {
          this.io.to(socketId).emit(event, messageData);
        });
        info(`Message sent to user ${userId}: ${event}`);
      }
    } catch (err) {
      error('Error sending message to user:', err);
      throw err;
    }
  }
}

export default WebSocketService;