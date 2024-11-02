/**
 * Human Tasks:
 * 1. Configure Elasticsearch cluster settings in production environment
 * 2. Set up Redis cluster for search result caching
 * 3. Configure geospatial index settings in Elasticsearch
 * 4. Set up monitoring for search performance metrics
 * 5. Review and adjust cache TTL settings based on usage patterns
 */

// External dependencies
import { Client } from '@elastic/elasticsearch'; // ^8.0.0
import Redis from 'ioredis'; // ^5.3.0
import { error, info } from '../utils/logger.utils';

// Internal dependencies
import createElasticsearchClient, { ES_INDICES, getSearchConfig } from '../config/elasticsearch';
import FurnitureModel from '../models/furniture.model';
import { validateCoordinates, generateBoundingBox, fuzzLocation } from '../utils/geo.utils';
import redisClient from '../config/redis';

// Types and interfaces
interface ISearchOptions {
  category?: string;
  condition?: string;
  sortBy?: string;
  page?: number;
  limit?: number;
  filters?: Record<string, any>;
}

interface ILocationSearchOptions extends ISearchOptions {
  privacyLevel?: string;
  includeUnavailable?: boolean;
}

interface ICoordinates {
  latitude: number;
  longitude: number;
}

interface SearchResult {
  id: string;
  score: number;
  item: Record<string, any>;
  highlights?: Record<string, string[]>;
}

interface LocationSearchResult extends SearchResult {
  distance: number;
}

/**
 * Service class implementing search functionality with caching and geospatial features
 * Addresses requirements: Location-based search, Search Infrastructure, Cache Layer
 */
class SearchService {
  private esClient: Client;
  private cacheClient: Redis;
  private readonly CACHE_TTL: number = 3600; // 1 hour in seconds

  constructor() {
    // Initialize Elasticsearch client
    this.esClient = createElasticsearchClient();
    
    // Initialize Redis client for caching
    this.cacheClient = redisClient;
  }

  /**
   * Performs full-text search for furniture items with optional location filtering
   * Addresses requirement: Search Infrastructure - Full-text search capabilities
   */
  public async searchFurniture(query: string, options: ISearchOptions = {}): Promise<SearchResult[]> {
    try {
      // Generate cache key based on search parameters
      const cacheKey = this.generateCacheKey('furniture', query, options);
      
      // Check cache first
      const cachedResults = await this.getCachedResults(cacheKey);
      if (cachedResults) {
        info('Returning cached search results');
        return cachedResults;
      }

      // Build search query
      const searchQuery = this.buildSearchQuery(query, options);
      
      // Execute search
      const response = await this.esClient.search({
        index: ES_INDICES.FURNITURE,
        ...getSearchConfig(ES_INDICES.FURNITURE),
        ...searchQuery
      });

      // Format and cache results
      const results = this.formatSearchResults(response);
      await this.cacheResults(cacheKey, results);

      return results;
    } catch (err) {
      error('Error performing furniture search', { error: err });
      throw err;
    }
  }

  /**
   * Searches for furniture items within a specified radius of coordinates
   * Addresses requirement: Location-based search - Geospatial search capabilities
   */
  public async searchByLocation(
    coordinates: ICoordinates,
    radius: number,
    options: ILocationSearchOptions = {}
  ): Promise<LocationSearchResult[]> {
    try {
      // Validate coordinates
      if (!validateCoordinates(coordinates)) {
        throw new Error('Invalid coordinates provided');
      }

      // Generate cache key for location search
      const cacheKey = this.generateCacheKey('location', `${coordinates.latitude},${coordinates.longitude}`, { radius, ...options });
      
      // Check cache
      const cachedResults = await this.getCachedResults(cacheKey);
      if (cachedResults) {
        info('Returning cached location search results');
        return cachedResults;
      }

      // Generate bounding box for efficient search
      const boundingBox = generateBoundingBox(coordinates, radius);

      // Build geospatial query
      const geoQuery = {
        bool: {
          must: [
            {
              geo_distance: {
                distance: `${radius}km`,
                location: {
                  lat: coordinates.latitude,
                  lon: coordinates.longitude
                }
              }
            }
          ],
          filter: [
            {
              term: {
                is_available: !options.includeUnavailable
              }
            }
          ]
        }
      };

      if (options.category) {
        geoQuery.bool.filter.push({
          term: { category: options.category }
        });
      }

      if (options.condition) {
        geoQuery.bool.filter.push({
          term: { condition: options.condition }
        });
      }

      // Execute search with geospatial query
      const response = await this.esClient.search({
        index: ES_INDICES.FURNITURE,
        query: geoQuery,
        sort: [
          {
            _geo_distance: {
              location: {
                lat: coordinates.latitude,
                lon: coordinates.longitude
              },
              order: 'asc',
              unit: 'km'
            }
          }
        ],
        size: options.limit || 50,
        from: (options.page || 0) * (options.limit || 50)
      });

      // Format results with distance information
      const results = this.formatLocationSearchResults(response, coordinates, options.privacyLevel);
      
      // Cache results
      await this.cacheResults(cacheKey, results);

      return results;
    } catch (err) {
      error('Error performing location-based search', { error: err });
      throw err;
    }
  }

  /**
   * Builds Elasticsearch query based on search parameters
   * Addresses requirement: Search Infrastructure - Query building
   */
  private buildSearchQuery(query: string, options: ISearchOptions): object {
    const searchQuery = {
      bool: {
        must: [
          {
            multi_match: {
              query,
              fields: ['title^2', 'description', 'material', 'category'],
              fuzziness: 'AUTO'
            }
          }
        ],
        filter: []
      }
    };

    // Add filters
    if (options.category) {
      searchQuery.bool.filter.push({
        term: { category: options.category }
      });
    }

    if (options.condition) {
      searchQuery.bool.filter.push({
        term: { condition: options.condition }
      });
    }

    // Add custom filters
    if (options.filters) {
      Object.entries(options.filters).forEach(([field, value]) => {
        searchQuery.bool.filter.push({
          term: { [field]: value }
        });
      });
    }

    return {
      query: searchQuery,
      size: options.limit || 50,
      from: (options.page || 0) * (options.limit || 50)
    };
  }

  /**
   * Retrieves cached search results if available
   * Addresses requirement: Cache Layer - Caching search results
   */
  private async getCachedResults(cacheKey: string): Promise<SearchResult[] | null> {
    try {
      const cached = await this.cacheClient.get(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }
      return null;
    } catch (err) {
      error('Error retrieving cached results', { error: err });
      return null;
    }
  }

  /**
   * Caches search results for future use
   * Addresses requirement: Cache Layer - Performance optimization
   */
  private async cacheResults(cacheKey: string, results: SearchResult[]): Promise<void> {
    try {
      await this.cacheClient.setex(
        cacheKey,
        this.CACHE_TTL,
        JSON.stringify(results)
      );
    } catch (err) {
      error('Error caching search results', { error: err });
    }
  }

  /**
   * Formats Elasticsearch response into standardized search results
   * Addresses requirement: Search Infrastructure - Result formatting
   */
  private formatSearchResults(response: any): SearchResult[] {
    return response.hits.hits.map((hit: any) => ({
      id: hit._id,
      score: hit._score,
      item: hit._source,
      highlights: hit.highlight
    }));
  }

  /**
   * Formats location search results with distance information
   * Addresses requirement: Location-based search - Distance calculation
   */
  private formatLocationSearchResults(
    response: any,
    searchCoordinates: ICoordinates,
    privacyLevel?: string
  ): LocationSearchResult[] {
    return response.hits.hits.map((hit: any) => {
      const source = hit._source;
      
      // Apply location privacy if needed
      if (privacyLevel && privacyLevel !== 'public') {
        source.location = fuzzLocation(
          {
            latitude: source.location.lat,
            longitude: source.location.lon
          },
          { visibilityLevel: privacyLevel, hideExactLocation: privacyLevel === 'private' }
        );
      }

      return {
        id: hit._id,
        score: hit._score,
        item: source,
        distance: hit.sort[0], // Distance in km from sort
        highlights: hit.highlight
      };
    });
  }

  /**
   * Generates a unique cache key based on search parameters
   * Addresses requirement: Cache Layer - Cache key generation
   */
  private generateCacheKey(type: string, query: string, options: Record<string, any>): string {
    const optionsString = Object.entries(options)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([key, value]) => `${key}:${JSON.stringify(value)}`)
      .join(',');
    
    return `search:${type}:${query}:${optionsString}`;
  }
}

export default SearchService;