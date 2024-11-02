// @package typescript ^5.0.0
import { Types } from 'typescript';
import { ILocation } from './location.interface';
import { IUser } from './user.interface';

/**
 * Enumeration of furniture categories
 * Addresses requirement: Furniture listing management - Core data structure definitions
 */
export enum FurnitureCategory {
  SEATING = 'SEATING',
  TABLES = 'TABLES',
  STORAGE = 'STORAGE',
  BEDS = 'BEDS',
  LIGHTING = 'LIGHTING',
  DECOR = 'DECOR',
  OUTDOOR = 'OUTDOOR',
  OTHER = 'OTHER'
}

/**
 * Enumeration of furniture conditions
 * Addresses requirement: Furniture listing management - Core data structure definitions
 */
export enum FurnitureCondition {
  LIKE_NEW = 'LIKE_NEW',
  GOOD = 'GOOD',
  FAIR = 'FAIR',
  NEEDS_REPAIR = 'NEEDS_REPAIR',
  FOR_PARTS = 'FOR_PARTS'
}

/**
 * Enumeration of furniture listing statuses
 * Addresses requirement: Furniture listing management - Core data structure definitions
 */
export enum FurnitureStatus {
  AVAILABLE = 'AVAILABLE',
  PENDING = 'PENDING',
  CLAIMED = 'CLAIMED',
  EXPIRED = 'EXPIRED',
  REMOVED = 'REMOVED'
}

/**
 * Enumeration of pickup arrangement types
 * Addresses requirement: Furniture listing management - Core data structure definitions
 */
export enum PickupType {
  PICKUP_WINDOW = 'PICKUP_WINDOW',
  BY_APPOINTMENT = 'BY_APPOINTMENT',
  FLEXIBLE = 'FLEXIBLE',
  IMMEDIATE = 'IMMEDIATE'
}

/**
 * Interface defining furniture dimensions
 * Addresses requirement: Furniture listing management - Core data structure definitions
 */
export interface IDimensions {
  length: number;
  width: number;
  height: number;
  weight: number;
  unit: string;
}

/**
 * Interface for AI-based quality assessment
 * Addresses requirement: AI/ML Infrastructure - Interface support for AI-generated metadata
 */
export interface IQualityAssessment {
  overallScore: number;
  detectedIssues: string[];
  recommendations: string[];
}

/**
 * Interface for AI-generated furniture metadata
 * Addresses requirement: AI/ML Infrastructure - Interface support for AI-generated metadata
 */
export interface IAIMetadata {
  style: string;
  confidenceScore: number;
  detectedMaterials: string[];
  suggestedCategories: string[];
  similarItems: string[];
  qualityAssessment: IQualityAssessment;
}

/**
 * Interface for furniture pickup arrangements
 * Addresses requirement: Furniture listing management - Core data structure definitions
 */
export interface IPickupDetails {
  type: PickupType;
  availableDays: string[];
  timeWindow: string;
  specialInstructions: string;
  assistanceRequired: boolean;
  requiredEquipment: string[];
}

/**
 * Main interface defining a furniture item in the system
 * Addresses requirements:
 * - Furniture listing management - Core data structure definitions
 * - AI/ML Infrastructure - Interface support for AI-generated metadata
 * - Location-based search - Integration with location services
 */
export interface IFurniture {
  id: string;
  userId: string;
  title: string;
  description: string;
  category: FurnitureCategory;
  condition: FurnitureCondition;
  dimensions: IDimensions;
  materials: string[];
  imageUrls: string[];
  aiMetadata: IAIMetadata;
  location: ILocation;
  status: FurnitureStatus;
  pickupDetails: IPickupDetails;
  createdAt: Date;
  updatedAt: Date;
  expiresAt: Date;
}