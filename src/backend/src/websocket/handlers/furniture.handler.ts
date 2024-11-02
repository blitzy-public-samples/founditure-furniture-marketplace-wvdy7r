/**
 * Human Tasks:
 * 1. Configure WebSocket event rate limiting in production
 * 2. Set up monitoring alerts for WebSocket connection thresholds
 * 3. Configure room-based scaling limits
 * 4. Review and adjust real-time update broadcast patterns
 * 5. Set up error tracking for WebSocket events
 */

// Third-party imports with versions
import { Socket } from 'socket.io'; // ^4.7.0

// Internal imports
import FurnitureService from '../../services/furniture.service';
import WebSocketService from '../../services/websocket.service';
import { IFurniture, FurnitureStatus } from '../../interfaces/furniture.interface';
import { error, info } from '../../utils/logger.utils';

/**
 * Handles WebSocket events for furniture-related operations
 * Addresses requirements:
 * - Real-time messaging system (1.2 Scope/Backend Services)
 * - System Interactions (3.4 System Interactions)
 */
export default class FurnitureHandler {
  private readonly furnitureService: FurnitureService;
  private readonly webSocketService: WebSocketService;

  constructor(
    furnitureService: FurnitureService,
    webSocketService: WebSocketService
  ) {
    this.furnitureService = furnitureService;
    this.webSocketService = webSocketService;
  }

  /**
   * Handles furniture creation events
   * Requirement: Real-time updates for furniture listings
   */
  public async handleFurnitureCreated(
    socket: Socket,
    furnitureData: IFurniture
  ): Promise<void> {
    try {
      // Validate user permissions
      if (!socket.data.userId) {
        throw new Error('Unauthorized');
      }

      // Create furniture using service
      const createdFurniture = await this.furnitureService.createFurniture(
        {
          ...furnitureData,
          userId: socket.data.userId
        },
        [] // Images are handled separately through HTTP endpoints
      );

      // Broadcast to relevant rooms
      this.webSocketService.broadcastToRoom(
        'furniture',
        'furniture_created',
        { furniture: createdFurniture }
      );

      // Send acknowledgment to sender
      socket.emit('furniture_created_ack', {
        success: true,
        furnitureId: createdFurniture.id
      });

      info(`Furniture created via WebSocket: ${createdFurniture.id}`);
    } catch (err) {
      error('Error handling furniture creation:', err);
      socket.emit('furniture_created_ack', {
        success: false,
        error: 'Failed to create furniture'
      });
    }
  }

  /**
   * Handles furniture update events
   * Requirement: Real-time updates for furniture listings
   */
  public async handleFurnitureUpdated(
    socket: Socket,
    furnitureId: string,
    updateData: Partial<IFurniture>
  ): Promise<void> {
    try {
      // Validate user permissions
      if (!socket.data.userId) {
        throw new Error('Unauthorized');
      }

      // Get existing furniture
      const existingFurniture = await this.furnitureService.getFurniture(furnitureId);
      if (existingFurniture.userId !== socket.data.userId) {
        throw new Error('Unauthorized to update this furniture');
      }

      // Update furniture using service
      const updatedFurniture = await this.furnitureService.updateFurniture(
        furnitureId,
        updateData
      );

      // Broadcast to relevant rooms
      this.webSocketService.broadcastToRoom(
        'furniture',
        'furniture_updated',
        { furniture: updatedFurniture }
      );

      // Send acknowledgment to sender
      socket.emit('furniture_updated_ack', {
        success: true,
        furnitureId: updatedFurniture.id
      });

      info(`Furniture updated via WebSocket: ${furnitureId}`);
    } catch (err) {
      error('Error handling furniture update:', err);
      socket.emit('furniture_updated_ack', {
        success: false,
        error: 'Failed to update furniture'
      });
    }
  }

  /**
   * Handles furniture deletion events
   * Requirement: Real-time updates for furniture listings
   */
  public async handleFurnitureDeleted(
    socket: Socket,
    furnitureId: string
  ): Promise<void> {
    try {
      // Validate user permissions
      if (!socket.data.userId) {
        throw new Error('Unauthorized');
      }

      // Get existing furniture
      const existingFurniture = await this.furnitureService.getFurniture(furnitureId);
      if (existingFurniture.userId !== socket.data.userId) {
        throw new Error('Unauthorized to delete this furniture');
      }

      // Delete furniture using service
      await this.furnitureService.deleteFurniture(furnitureId);

      // Broadcast to relevant rooms
      this.webSocketService.broadcastToRoom(
        'furniture',
        'furniture_deleted',
        { furnitureId }
      );

      // Send acknowledgment to sender
      socket.emit('furniture_deleted_ack', {
        success: true,
        furnitureId
      });

      info(`Furniture deleted via WebSocket: ${furnitureId}`);
    } catch (err) {
      error('Error handling furniture deletion:', err);
      socket.emit('furniture_deleted_ack', {
        success: false,
        error: 'Failed to delete furniture'
      });
    }
  }

  /**
   * Handles furniture status change events
   * Requirement: Real-time updates for furniture listings
   */
  public async handleStatusChange(
    socket: Socket,
    furnitureId: string,
    newStatus: FurnitureStatus
  ): Promise<void> {
    try {
      // Validate user permissions
      if (!socket.data.userId) {
        throw new Error('Unauthorized');
      }

      // Get existing furniture
      const existingFurniture = await this.furnitureService.getFurniture(furnitureId);
      if (existingFurniture.userId !== socket.data.userId) {
        throw new Error('Unauthorized to change status of this furniture');
      }

      // Update status using service
      const updatedFurniture = await this.furnitureService.updateFurnitureStatus(
        furnitureId,
        newStatus
      );

      // Broadcast to relevant rooms
      this.webSocketService.broadcastToRoom(
        'furniture',
        'furniture_status_changed',
        {
          furnitureId,
          status: newStatus,
          updatedAt: updatedFurniture.updatedAt
        }
      );

      // Send acknowledgment to sender
      socket.emit('furniture_status_changed_ack', {
        success: true,
        furnitureId,
        status: newStatus
      });

      info(`Furniture status changed via WebSocket: ${furnitureId} -> ${newStatus}`);
    } catch (err) {
      error('Error handling furniture status change:', err);
      socket.emit('furniture_status_changed_ack', {
        success: false,
        error: 'Failed to change furniture status'
      });
    }
  }

  /**
   * Subscribes a socket to furniture updates
   * Requirement: Real-time updates for furniture listings
   */
  public async subscribeToFurniture(
    socket: Socket,
    furnitureId: string
  ): Promise<void> {
    try {
      // Validate furniture exists
      await this.furnitureService.getFurniture(furnitureId);

      // Add socket to furniture room
      socket.join(`furniture:${furnitureId}`);

      // Send subscription confirmation
      socket.emit('furniture_subscribed', {
        success: true,
        furnitureId
      });

      info(`Socket subscribed to furniture updates: ${socket.id} -> ${furnitureId}`);
    } catch (err) {
      error('Error subscribing to furniture updates:', err);
      socket.emit('furniture_subscribed', {
        success: false,
        error: 'Failed to subscribe to furniture updates'
      });
    }
  }

  /**
   * Unsubscribes a socket from furniture updates
   * Requirement: Real-time updates for furniture listings
   */
  public async unsubscribeFromFurniture(
    socket: Socket,
    furnitureId: string
  ): Promise<void> {
    try {
      // Remove socket from furniture room
      socket.leave(`furniture:${furnitureId}`);

      // Send unsubscription confirmation
      socket.emit('furniture_unsubscribed', {
        success: true,
        furnitureId
      });

      info(`Socket unsubscribed from furniture updates: ${socket.id} -> ${furnitureId}`);
    } catch (err) {
      error('Error unsubscribing from furniture updates:', err);
      socket.emit('furniture_unsubscribed', {
        success: false,
        error: 'Failed to unsubscribe from furniture updates'
      });
    }
  }
}