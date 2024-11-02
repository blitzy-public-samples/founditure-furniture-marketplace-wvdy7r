/**
 * Human Tasks:
 * 1. Configure WebSocket port in environment variables (default: 3001)
 * 2. Set up CORS origin whitelist in environment variables
 * 3. Configure WebSocket ping intervals in environment variables
 * 4. Set up Redis adapter cluster configuration in production
 * 5. Configure SSL/TLS certificates for secure WebSocket in production
 */

// Third-party imports with versions
import { Server } from 'socket.io'; // ^4.7.0
import { createAdapter } from '@socket.io/redis-adapter'; // ^8.2.0
import { Server as HttpServer } from 'http';

// Internal imports
import { ERROR_CODES } from '../constants/error-codes';
import redisClient from './redis';

// Environment variables with defaults
const WEBSOCKET_PORT = parseInt(process.env.WEBSOCKET_PORT || '3001');
const WEBSOCKET_PATH = process.env.WEBSOCKET_PATH || '/ws';
const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';
const PING_TIMEOUT = parseInt(process.env.WS_PING_TIMEOUT || '10000');
const PING_INTERVAL = parseInt(process.env.WS_PING_INTERVAL || '5000');

/**
 * Validates WebSocket configuration settings
 * Requirements: Real-time Updates (3.1 High-Level Architecture Overview)
 */
export const validateWebSocketConfig = (): boolean => {
  try {
    // Validate port range
    if (WEBSOCKET_PORT < 1 || WEBSOCKET_PORT > 65535) {
      throw new Error('Invalid WebSocket port configuration');
    }

    // Validate ping settings
    if (PING_TIMEOUT < 1000 || PING_INTERVAL < 1000) {
      throw new Error('Invalid ping configuration');
    }

    // Validate Redis connection for adapter
    if (!redisClient.status || redisClient.status !== 'ready') {
      throw new Error('Redis client not ready for WebSocket adapter');
    }

    // Validate CORS settings in production
    if (process.env.NODE_ENV === 'production' && CORS_ORIGIN === '*') {
      throw new Error('Wildcard CORS origin not allowed in production');
    }

    return true;
  } catch (error) {
    console.error('WebSocket configuration validation failed:', error);
    return false;
  }
};

/**
 * Configures WebSocket event handlers
 * Requirements: 
 * - Real-time Messaging (4.2.2)
 * - Push Notifications (1.2 Scope/Core System Components)
 */
const configureWebSocketEvents = (io: Server): void => {
  io.on('connection', (socket) => {
    // User authentication and session management
    socket.on('authenticate', async (token: string) => {
      try {
        // Authentication logic here
        socket.data.authenticated = true;
        socket.emit('authenticated');
      } catch (error) {
        socket.emit('error', { code: ERROR_CODES.AUTH_INVALID_CREDENTIALS });
      }
    });

    // Real-time messaging handlers
    socket.on('message', async (data: { recipientId: string; content: string }) => {
      try {
        // Message sending logic here
        io.to(data.recipientId).emit('new_message', {
          senderId: socket.id,
          content: data.content
        });
      } catch (error) {
        socket.emit('error', { code: ERROR_CODES.MESSAGE_SEND_FAILED });
      }
    });

    // Furniture update handlers
    socket.on('furniture_update', (data: { furnitureId: string; update: any }) => {
      try {
        // Broadcast furniture updates to relevant users
        socket.broadcast.emit('furniture_changed', data);
      } catch (error) {
        socket.emit('error', { code: ERROR_CODES.FURNITURE_UPDATE_FAILED });
      }
    });

    // Location update handlers
    socket.on('location_update', (data: { latitude: number; longitude: number }) => {
      try {
        // Update user location and notify relevant users
        socket.broadcast.emit('user_moved', {
          userId: socket.id,
          location: data
        });
      } catch (error) {
        socket.emit('error', { code: ERROR_CODES.LOCATION_UPDATE_FAILED });
      }
    });

    // Error handlers
    socket.on('error', (error) => {
      console.error('WebSocket error:', error);
      socket.emit('error', { code: ERROR_CODES.NETWORK_CONNECTION_ERROR });
    });

    // Disconnect handlers
    socket.on('disconnect', () => {
      // Clean up user session and notify relevant users
      socket.broadcast.emit('user_offline', { userId: socket.id });
    });
  });
};

/**
 * Creates and configures the WebSocket server
 * Requirements: Real-time Updates (3.1 High-Level Architecture Overview)
 */
const createWebSocketServer = (httpServer: HttpServer): Server => {
  // Create Socket.IO server instance
  const io = new Server(httpServer, {
    path: WEBSOCKET_PATH,
    cors: {
      origin: CORS_ORIGIN,
      methods: ['GET', 'POST'],
      credentials: true
    },
    pingTimeout: PING_TIMEOUT,
    pingInterval: PING_INTERVAL,
    transports: ['websocket', 'polling'],
    allowEIO3: true
  });

  // Set up Redis adapter for horizontal scaling
  const pubClient = redisClient.duplicate();
  const subClient = redisClient.duplicate();

  io.adapter(createAdapter(pubClient, subClient));

  // Configure event handlers
  configureWebSocketEvents(io);

  // Error handling for adapter
  pubClient.on('error', (error) => {
    console.error('Redis pub client error:', error);
  });

  subClient.on('error', (error) => {
    console.error('Redis sub client error:', error);
  });

  return io;
};

export default createWebSocketServer;