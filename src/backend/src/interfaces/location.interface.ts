// mongoose v7.x
import { Types } from 'mongoose';

/**
 * Interface defining geographic coordinate structure
 * Addresses requirement: Location Services - Core location services functionality
 */
export interface ICoordinates {
  latitude: number;
  longitude: number;
  accuracy?: number;
  altitude?: number;
}

/**
 * Interface for location privacy configuration
 * Addresses requirement: Privacy Controls - Location privacy settings and data protection
 */
export interface IPrivacySettings {
  visibilityLevel: string;
  blurRadius: number;
  hideExactLocation: boolean;
}

/**
 * Enumeration of possible location types
 * Addresses requirement: Location-based Search - Geospatial search capabilities
 */
export enum LocationType {
  PICKUP_POINT = 'PICKUP_POINT',
  DROP_OFF_POINT = 'DROP_OFF_POINT',
  USER_LOCATION = 'USER_LOCATION',
  FURNITURE_LOCATION = 'FURNITURE_LOCATION',
  MEETING_POINT = 'MEETING_POINT'
}

/**
 * Main interface for location data
 * Addresses requirements:
 * - Location Services - Core location services functionality
 * - Privacy Controls - Location privacy settings
 * - Location-based Search - Geospatial search capabilities
 */
export interface ILocation {
  id: Types.ObjectId;
  userId: Types.ObjectId;
  coordinates: ICoordinates;
  address: string;
  city: string;
  state: string;
  country: string;
  postalCode: string;
  type: LocationType;
  privacySettings: IPrivacySettings;
  createdAt: Date;
  updatedAt: Date;
}