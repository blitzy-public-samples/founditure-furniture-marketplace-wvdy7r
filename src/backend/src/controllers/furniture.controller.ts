/**
 * Human Tasks:
 * 1. Configure Multer upload limits in infrastructure
 * 2. Set up monitoring for file upload performance
 * 3. Configure CDN caching rules for furniture images
 * 4. Review and adjust rate limiting for furniture endpoints
 * 5. Set up alerts for AI service processing errors
 */

// Third-party imports with versions
import { Request, Response, NextFunction } from 'express'; // ^4.18.0
import { StatusCodes } from 'http-status-codes'; // ^2.2.0
import multer from 'multer'; // ^1.4.5-lts.1

// Internal imports
import FurnitureService from '../services/furniture.service';
import { IFurniture, FurnitureStatus } from '../interfaces/furniture.interface';
import { 
  validateFurnitureCreate, 
  validateFurnitureUpdate, 
  validateFurnitureStatus 
} from '../validators/furniture.validator';
import { AppError } from '../middleware/error.middleware';

/**
 * Controller handling furniture-related HTTP endpoints
 * Addresses requirements:
 * - Furniture listing management (1.2 Scope/Core System Components)
 * - Location-based search (1.2 Scope/Included Features)
 * - Content moderation (1.2 Scope/Included Features)
 */
export default class FurnitureController {
  private readonly furnitureService: FurnitureService;

  constructor(furnitureService: FurnitureService) {
    this.furnitureService = furnitureService;
  }

  /**
   * Creates a new furniture listing with images
   * Addresses requirement: Furniture listing management
   */
  public createFurniture = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const furnitureData = req.body;
      const images = (req.files as Express.Multer.File[]) || [];

      // Validate furniture data
      const validationResult = await validateFurnitureCreate(furnitureData);
      if (!validationResult.isValid) {
        throw new AppError(
          validationResult.errorCode!,
          StatusCodes.BAD_REQUEST,
          validationResult.errorMessage!
        );
      }

      // Validate images
      if (images.length === 0) {
        throw new AppError(
          'FURNITURE_NO_IMAGES',
          StatusCodes.BAD_REQUEST,
          'At least one image is required'
        );
      }

      // Convert images to buffers
      const imageBuffers = images.map(image => image.buffer);

      // Create furniture with validated data
      const furniture = await this.furnitureService.createFurniture(
        validationResult.validatedData!,
        imageBuffers
      );

      res.status(StatusCodes.CREATED).json({
        status: 'success',
        data: furniture
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Retrieves a furniture listing by ID
   * Addresses requirement: Furniture listing management
   */
  public getFurniture = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const { id } = req.params;

      const furniture = await this.furnitureService.getFurniture(id);

      res.status(StatusCodes.OK).json({
        status: 'success',
        data: furniture
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Searches furniture listings by criteria
   * Addresses requirements:
   * - Furniture listing management
   * - Location-based search
   */
  public searchFurniture = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const {
        query,
        category,
        condition,
        lat,
        lng,
        radius,
        status,
        page,
        limit
      } = req.query;

      // Build search criteria
      const searchCriteria: any = {};
      
      if (query) searchCriteria.query = String(query);
      if (category) searchCriteria.category = String(category);
      if (condition) searchCriteria.condition = String(condition);
      if (status) searchCriteria.status = String(status);
      if (page) searchCriteria.page = Number(page);
      if (limit) searchCriteria.limit = Number(limit);

      // Add location search if coordinates provided
      if (lat && lng && radius) {
        searchCriteria.location = {
          lat: Number(lat),
          lng: Number(lng),
          radius: Number(radius)
        };
      }

      const results = await this.furnitureService.searchFurniture(searchCriteria);

      res.status(StatusCodes.OK).json({
        status: 'success',
        data: results.items,
        meta: {
          total: results.total,
          page: searchCriteria.page || 1,
          limit: searchCriteria.limit || 20
        }
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Updates a furniture listing
   * Addresses requirements:
   * - Furniture listing management
   * - Content moderation
   */
  public updateFurniture = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const { id } = req.params;
      const updateData = req.body;
      const newImages = (req.files as Express.Multer.File[]) || [];

      // Validate update data
      const validationResult = await validateFurnitureUpdate(updateData, id);
      if (!validationResult.isValid) {
        throw new AppError(
          validationResult.errorCode!,
          StatusCodes.BAD_REQUEST,
          validationResult.errorMessage!
        );
      }

      // Convert new images to buffers if provided
      const imageBuffers = newImages.length > 0 
        ? newImages.map(image => image.buffer)
        : undefined;

      // Update furniture with validated data
      const furniture = await this.furnitureService.updateFurniture(
        id,
        validationResult.validatedData!,
        imageBuffers
      );

      res.status(StatusCodes.OK).json({
        status: 'success',
        data: furniture
      });
    } catch (error) {
      next(error);
    }
  };

  /**
   * Deletes a furniture listing
   * Addresses requirement: Furniture listing management
   */
  public deleteFurniture = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const { id } = req.params;

      await this.furnitureService.deleteFurniture(id);

      res.status(StatusCodes.NO_CONTENT).send();
    } catch (error) {
      next(error);
    }
  };

  /**
   * Updates the status of a furniture listing
   * Addresses requirement: Furniture listing management
   */
  public updateFurnitureStatus = async (
    req: Request,
    res: Response,
    next: NextFunction
  ): Promise<void> => {
    try {
      const { id } = req.params;
      const { status } = req.body;

      // Validate status update
      const validationResult = await validateFurnitureStatus(status, id);
      if (!validationResult.isValid) {
        throw new AppError(
          validationResult.errorCode!,
          StatusCodes.BAD_REQUEST,
          validationResult.errorMessage!
        );
      }

      const furniture = await this.furnitureService.updateFurnitureStatus(
        id,
        status as FurnitureStatus
      );

      res.status(StatusCodes.OK).json({
        status: 'success',
        data: furniture
      });
    } catch (error) {
      next(error);
    }
  };
}