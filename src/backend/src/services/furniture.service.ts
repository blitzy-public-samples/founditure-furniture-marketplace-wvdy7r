/**
 * Human Tasks:
 * 1. Configure MongoDB indexes for optimal query performance
 * 2. Set up monitoring alerts for storage usage thresholds
 * 3. Configure AI service processing timeouts
 * 4. Review and adjust rate limiting for real-time updates
 * 5. Set up backup strategy for furniture images
 * 6. Configure geospatial query optimization parameters
 */

// Third-party imports with versions
import mongoose, { FilterQuery } from 'mongoose'; // ^7.0.0
import sharp from 'sharp'; // ^0.32.x

// Internal dependencies
import { IFurniture, FurnitureStatus } from '../interfaces/furniture.interface';
import FurnitureModel from '../models/furniture.model';
import AIService from './ai.service';
import StorageService from './storage.service';
import WebSocketService from './websocket.service';
import { error, info, debug } from '../utils/logger.utils';

/**
 * Service class handling all furniture-related operations
 * Addresses requirements:
 * - Furniture listing management (1.2 Scope/Core System Components)
 * - AI/ML Infrastructure integration (1.2 Scope/Core System Components)
 * - Location-based search (1.2 Scope/Included Features)
 */
export default class FurnitureService {
  private readonly aiService: AIService;
  private readonly storageService: StorageService;
  private readonly webSocketService: WebSocketService;

  constructor(
    aiService: AIService,
    storageService: StorageService,
    webSocketService: WebSocketService
  ) {
    this.aiService = aiService;
    this.storageService = storageService;
    this.webSocketService = webSocketService;

    // Set up event listeners for real-time updates
    this.initializeEventListeners();
    info('FurnitureService initialized successfully');
  }

  /**
   * Initializes event listeners for real-time updates
   * Addresses requirement: Real-time updates for furniture listings
   */
  private initializeEventListeners(): void {
    try {
      this.webSocketService.on('furniture_update', (data: any) => {
        debug('Received furniture update event:', data);
      });
    } catch (err) {
      error('Failed to initialize event listeners:', err);
      throw new Error('Event listener initialization failed');
    }
  }

  /**
   * Creates a new furniture listing with AI processing
   * Addresses requirements:
   * - Furniture listing management
   * - AI/ML Infrastructure integration
   */
  public async createFurniture(
    furnitureData: Omit<IFurniture, 'id' | 'imageUrls' | 'aiMetadata'>,
    images: Buffer[]
  ): Promise<IFurniture> {
    try {
      // Validate input data
      if (!furnitureData || !images.length) {
        throw new Error('Invalid furniture data or images');
      }

      // Process images with AI service
      const processedImages = await Promise.all(
        images.map(async (image) => {
          const aiMetadata = await this.aiService.analyzeFurnitureImage(image);
          const optimizedImage = await sharp(image)
            .resize(1200, 1200, { fit: 'inside' })
            .webp({ quality: 80 })
            .toBuffer();
          
          const imageUrl = await this.storageService.uploadFurnitureImage(
            optimizedImage,
            `${Date.now()}.webp`,
            'image/webp'
          );

          return { url: imageUrl, metadata: aiMetadata };
        })
      );

      // Create furniture document
      const furniture = new FurnitureModel({
        ...furnitureData,
        imageUrls: processedImages.map(img => img.url),
        aiMetadata: processedImages[0].metadata, // Use primary image metadata
        status: FurnitureStatus.AVAILABLE,
        createdAt: new Date(),
        updatedAt: new Date(),
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days expiration
      });

      await furniture.save();

      // Broadcast creation event
      this.webSocketService.broadcastToRoom(
        'furniture',
        'furniture_created',
        { furniture: furniture.toJSON() }
      );

      info(`Created furniture listing: ${furniture.id}`);
      return furniture;
    } catch (err) {
      error('Failed to create furniture listing:', err);
      throw new Error('Furniture creation failed');
    }
  }

  /**
   * Retrieves a furniture listing by ID
   * Addresses requirement: Furniture listing management
   */
  public async getFurniture(id: string): Promise<IFurniture> {
    try {
      const furniture = await FurnitureModel.findById(id);
      if (!furniture) {
        throw new Error('Furniture not found');
      }
      return furniture;
    } catch (err) {
      error('Failed to retrieve furniture:', err);
      throw new Error('Furniture retrieval failed');
    }
  }

  /**
   * Searches furniture listings by criteria
   * Addresses requirements:
   * - Furniture listing management
   * - Location-based search
   */
  public async searchFurniture(searchCriteria: {
    query?: string;
    category?: string;
    condition?: string;
    location?: { lat: number; lng: number; radius: number };
    status?: FurnitureStatus;
    page?: number;
    limit?: number;
  }): Promise<{ items: IFurniture[]; total: number }> {
    try {
      const {
        query,
        category,
        condition,
        location,
        status = FurnitureStatus.AVAILABLE,
        page = 1,
        limit = 20
      } = searchCriteria;

      // Build base query
      const baseQuery: FilterQuery<IFurniture> = {
        status,
        expiresAt: { $gt: new Date() }
      };

      // Add text search if provided
      if (query) {
        baseQuery.$text = { $search: query };
      }

      // Add category filter
      if (category) {
        baseQuery.category = category;
      }

      // Add condition filter
      if (condition) {
        baseQuery.condition = condition;
      }

      // Add geospatial query if location provided
      if (location) {
        baseQuery.location = {
          $near: {
            $geometry: {
              type: 'Point',
              coordinates: [location.lng, location.lat]
            },
            $maxDistance: location.radius * 1000 // Convert km to meters
          }
        };
      }

      // Execute paginated search
      const [items, total] = await Promise.all([
        FurnitureModel.find(baseQuery)
          .skip((page - 1) * limit)
          .limit(limit)
          .sort({ createdAt: -1 }),
        FurnitureModel.countDocuments(baseQuery)
      ]);

      return { items, total };
    } catch (err) {
      error('Failed to search furniture:', err);
      throw new Error('Furniture search failed');
    }
  }

  /**
   * Updates a furniture listing
   * Addresses requirements:
   * - Furniture listing management
   * - AI/ML Infrastructure integration
   */
  public async updateFurniture(
    id: string,
    updateData: Partial<IFurniture>,
    newImages?: Buffer[]
  ): Promise<IFurniture> {
    try {
      const furniture = await FurnitureModel.findById(id);
      if (!furniture) {
        throw new Error('Furniture not found');
      }

      // Process new images if provided
      if (newImages?.length) {
        const processedImages = await Promise.all(
          newImages.map(async (image) => {
            const aiMetadata = await this.aiService.analyzeFurnitureImage(image);
            const optimizedImage = await sharp(image)
              .resize(1200, 1200, { fit: 'inside' })
              .webp({ quality: 80 })
              .toBuffer();
            
            const imageUrl = await this.storageService.uploadFurnitureImage(
              optimizedImage,
              `${Date.now()}.webp`,
              'image/webp'
            );

            return { url: imageUrl, metadata: aiMetadata };
          })
        );

        // Delete old images
        await Promise.all(
          furniture.imageUrls.map(url => this.storageService.deleteFurnitureImage(url))
        );

        // Update image URLs and AI metadata
        updateData.imageUrls = processedImages.map(img => img.url);
        updateData.aiMetadata = processedImages[0].metadata;
      }

      // Update furniture document
      Object.assign(furniture, updateData);
      furniture.updatedAt = new Date();
      await furniture.save();

      // Broadcast update event
      this.webSocketService.broadcastToRoom(
        'furniture',
        'furniture_updated',
        { furniture: furniture.toJSON() }
      );

      info(`Updated furniture listing: ${furniture.id}`);
      return furniture;
    } catch (err) {
      error('Failed to update furniture:', err);
      throw new Error('Furniture update failed');
    }
  }

  /**
   * Deletes a furniture listing
   * Addresses requirement: Furniture listing management
   */
  public async deleteFurniture(id: string): Promise<boolean> {
    try {
      const furniture = await FurnitureModel.findById(id);
      if (!furniture) {
        throw new Error('Furniture not found');
      }

      // Delete associated images
      await Promise.all(
        furniture.imageUrls.map(url => this.storageService.deleteFurnitureImage(url))
      );

      // Remove furniture document
      await furniture.deleteOne();

      // Broadcast deletion event
      this.webSocketService.broadcastToRoom(
        'furniture',
        'furniture_deleted',
        { furnitureId: id }
      );

      info(`Deleted furniture listing: ${id}`);
      return true;
    } catch (err) {
      error('Failed to delete furniture:', err);
      throw new Error('Furniture deletion failed');
    }
  }

  /**
   * Updates the status of a furniture listing
   * Addresses requirement: Furniture listing management
   */
  public async updateFurnitureStatus(
    id: string,
    status: FurnitureStatus
  ): Promise<IFurniture> {
    try {
      const furniture = await FurnitureModel.findById(id);
      if (!furniture) {
        throw new Error('Furniture not found');
      }

      // Validate status transition
      if (furniture.status === FurnitureStatus.REMOVED) {
        throw new Error('Cannot update status of removed furniture');
      }

      // Update status
      furniture.status = status;
      furniture.updatedAt = new Date();
      await furniture.save();

      // Broadcast status change
      this.webSocketService.broadcastToRoom(
        'furniture',
        'furniture_status_updated',
        { furnitureId: id, status }
      );

      info(`Updated furniture status: ${id} -> ${status}`);
      return furniture;
    } catch (err) {
      error('Failed to update furniture status:', err);
      throw new Error('Status update failed');
    }
  }
}