// geolib v3.3.4
import { getDistance, getBoundsOfDistance, computeDestinationPoint, isPointInCircle } from 'geolib';
import { ICoordinates, IPrivacySettings } from '../interfaces/location.interface';

/**
 * HUMAN TASKS:
 * 1. Verify that the geolib package is installed with correct version: npm install geolib@3.3.4
 * 2. Configure environment variables for default privacy settings if needed
 * 3. Review and adjust privacy radius constants based on regional requirements
 */

// Constants for coordinate validation and privacy settings
const MAX_LATITUDE = 90;
const MIN_LATITUDE = -90;
const MAX_LONGITUDE = 180;
const MIN_LONGITUDE = -180;
const DEFAULT_BLUR_RADIUS = 0.5; // km
const COORDINATE_PRECISION = 6; // decimal places

/**
 * Validates geographic coordinates to ensure they are within valid ranges
 * Addresses requirement: Location Services - Core location services functionality
 */
export const validateCoordinates = (coordinates: ICoordinates): boolean => {
  if (!coordinates || typeof coordinates.latitude !== 'number' || typeof coordinates.longitude !== 'number') {
    return false;
  }

  if (coordinates.latitude > MAX_LATITUDE || coordinates.latitude < MIN_LATITUDE) {
    return false;
  }

  if (coordinates.longitude > MAX_LONGITUDE || coordinates.longitude < MIN_LONGITUDE) {
    return false;
  }

  if (coordinates.accuracy !== undefined && (coordinates.accuracy < 0 || !Number.isFinite(coordinates.accuracy))) {
    return false;
  }

  if (coordinates.altitude !== undefined && !Number.isFinite(coordinates.altitude)) {
    return false;
  }

  return true;
};

/**
 * Calculates the distance between two geographic coordinates
 * Addresses requirement: Location-based Search - Geospatial search capabilities
 */
export const calculateDistance = (point1: ICoordinates, point2: ICoordinates, unit: string = 'km'): number => {
  if (!validateCoordinates(point1) || !validateCoordinates(point2)) {
    throw new Error('Invalid coordinates provided');
  }

  const distanceInMeters = getDistance(
    { latitude: point1.latitude, longitude: point1.longitude },
    { latitude: point2.latitude, longitude: point2.longitude }
  );

  if (unit.toLowerCase() === 'miles') {
    return Number((distanceInMeters / 1609.344).toFixed(2));
  }

  return Number((distanceInMeters / 1000).toFixed(2));
};

/**
 * Applies privacy settings to coordinates by adding randomization or reducing precision
 * Addresses requirement: Privacy Controls - Location privacy settings and data protection
 */
export const fuzzLocation = (coordinates: ICoordinates, privacySettings: IPrivacySettings): ICoordinates => {
  if (!validateCoordinates(coordinates)) {
    throw new Error('Invalid coordinates provided');
  }

  const { visibilityLevel, blurRadius, hideExactLocation } = privacySettings;

  if (hideExactLocation || visibilityLevel === 'private') {
    // Generate a random angle and distance within blur radius
    const angle = Math.random() * 360;
    const distance = Math.random() * (blurRadius || DEFAULT_BLUR_RADIUS) * 1000; // Convert to meters

    const fuzzyPoint = computeDestinationPoint(
      { latitude: coordinates.latitude, longitude: coordinates.longitude },
      distance,
      angle
    );

    return {
      latitude: Number(fuzzyPoint.latitude.toFixed(COORDINATE_PRECISION)),
      longitude: Number(fuzzyPoint.longitude.toFixed(COORDINATE_PRECISION)),
      accuracy: coordinates.accuracy,
      altitude: coordinates.altitude
    };
  }

  // Reduce precision for semi-private visibility
  if (visibilityLevel === 'semi-private') {
    return {
      latitude: Number(coordinates.latitude.toFixed(COORDINATE_PRECISION - 2)),
      longitude: Number(coordinates.longitude.toFixed(COORDINATE_PRECISION - 2)),
      accuracy: coordinates.accuracy,
      altitude: coordinates.altitude
    };
  }

  return coordinates;
};

/**
 * Checks if a point is within a specified radius of a center point
 * Addresses requirement: Location-based Search - Geospatial search capabilities
 */
export const isWithinRadius = (center: ICoordinates, point: ICoordinates, radiusInKm: number): boolean => {
  if (!validateCoordinates(center) || !validateCoordinates(point) || radiusInKm <= 0) {
    throw new Error('Invalid parameters provided');
  }

  return isPointInCircle(
    { latitude: point.latitude, longitude: point.longitude },
    { latitude: center.latitude, longitude: center.longitude },
    radiusInKm * 1000 // Convert to meters
  );
};

/**
 * Generates a bounding box for geospatial queries given a center point and radius
 * Addresses requirement: Location-based Search - Geospatial search capabilities
 */
export const generateBoundingBox = (center: ICoordinates, radiusInKm: number): { 
  minLat: number;
  maxLat: number;
  minLng: number;
  maxLng: number;
} => {
  if (!validateCoordinates(center) || radiusInKm <= 0) {
    throw new Error('Invalid parameters provided');
  }

  const bounds = getBoundsOfDistance(
    { latitude: center.latitude, longitude: center.longitude },
    radiusInKm * 1000 // Convert to meters
  );

  return {
    minLat: Number(bounds[0].latitude.toFixed(COORDINATE_PRECISION)),
    maxLat: Number(bounds[1].latitude.toFixed(COORDINATE_PRECISION)),
    minLng: Number(bounds[0].longitude.toFixed(COORDINATE_PRECISION)),
    maxLng: Number(bounds[1].longitude.toFixed(COORDINATE_PRECISION))
  };
};