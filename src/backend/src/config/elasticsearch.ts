/**
 * Human Tasks:
 * 1. Set up Elasticsearch cluster in production environment
 * 2. Configure authentication credentials in environment variables
 * 3. Set up SSL/TLS certificates for secure communication
 * 4. Configure index replication and backup policies
 * 5. Set up monitoring and alerting for Elasticsearch cluster
 */

// @elastic/elasticsearch@8.0.0
import { Client } from '@elastic/elasticsearch';
import { error, info } from '../utils/logger.utils';
import { ERROR_CODES } from '../constants/error-codes';

// Global configuration for Elasticsearch indices
export const ES_INDICES = {
  FURNITURE: 'furniture',
  USERS: 'users',
  MESSAGES: 'messages'
} as const;

// Requirement: Search Infrastructure - Index settings for furniture data
const FURNITURE_INDEX_SETTINGS = {
  settings: {
    number_of_shards: 3,
    number_of_replicas: 2,
    analysis: {
      analyzer: {
        furniture_analyzer: {
          type: 'custom',
          tokenizer: 'standard',
          filter: ['lowercase', 'asciifolding', 'word_delimiter']
        }
      }
    }
  },
  mappings: {
    properties: {
      title: { type: 'text', analyzer: 'furniture_analyzer' },
      description: { type: 'text', analyzer: 'furniture_analyzer' },
      category: { type: 'keyword' },
      material: { type: 'keyword' },
      condition: { type: 'keyword' },
      dimensions: {
        properties: {
          width: { type: 'float' },
          height: { type: 'float' },
          depth: { type: 'float' }
        }
      },
      location: { type: 'geo_point' },
      created_at: { type: 'date' },
      user_id: { type: 'keyword' },
      is_available: { type: 'boolean' }
    }
  }
};

// Requirement: Data Storage - Search index configuration for user data
const USER_INDEX_SETTINGS = {
  settings: {
    number_of_shards: 2,
    number_of_replicas: 1,
    analysis: {
      analyzer: {
        user_analyzer: {
          type: 'custom',
          tokenizer: 'standard',
          filter: ['lowercase', 'asciifolding']
        }
      }
    }
  },
  mappings: {
    properties: {
      email: { type: 'keyword' },
      full_name: { type: 'text', analyzer: 'user_analyzer' },
      location: { type: 'geo_point' },
      created_at: { type: 'date' },
      last_active: { type: 'date' },
      points: { type: 'integer' }
    }
  }
};

// Requirement: Data Storage - Search index configuration for message data
const MESSAGE_INDEX_SETTINGS = {
  settings: {
    number_of_shards: 2,
    number_of_replicas: 1
  },
  mappings: {
    properties: {
      sender_id: { type: 'keyword' },
      receiver_id: { type: 'keyword' },
      content: { type: 'text' },
      sent_at: { type: 'date' },
      read_at: { type: 'date' },
      furniture_id: { type: 'keyword' }
    }
  }
};

// Requirement: Search Infrastructure - Elasticsearch client configuration
const createElasticsearchClient = (): Client => {
  try {
    const client = new Client({
      node: process.env.ES_CONFIG?.node || 'http://localhost:9200',
      auth: {
        username: process.env.ES_CONFIG?.auth?.username || 'elastic',
        password: process.env.ES_CONFIG?.auth?.password || 'changeme'
      },
      tls: {
        rejectUnauthorized: process.env.ES_CONFIG?.tls?.rejectUnauthorized ?? true
      },
      maxRetries: 3,
      requestTimeout: 30000,
      sniffOnStart: true
    });

    info('Elasticsearch client created successfully');
    return client;
  } catch (err) {
    error('Failed to create Elasticsearch client', { error: err, code: ERROR_CODES.DATABASE_ERROR });
    throw err;
  }
};

// Requirement: Search Infrastructure - Initialize Elasticsearch indices
const initializeIndices = async (esClient: Client): Promise<void> => {
  try {
    // Initialize furniture index
    const furnitureExists = await esClient.indices.exists({ index: ES_INDICES.FURNITURE });
    if (!furnitureExists) {
      await esClient.indices.create({
        index: ES_INDICES.FURNITURE,
        ...FURNITURE_INDEX_SETTINGS
      });
      info(`Created ${ES_INDICES.FURNITURE} index`);
    }

    // Initialize users index
    const usersExists = await esClient.indices.exists({ index: ES_INDICES.USERS });
    if (!usersExists) {
      await esClient.indices.create({
        index: ES_INDICES.USERS,
        ...USER_INDEX_SETTINGS
      });
      info(`Created ${ES_INDICES.USERS} index`);
    }

    // Initialize messages index
    const messagesExists = await esClient.indices.exists({ index: ES_INDICES.MESSAGES });
    if (!messagesExists) {
      await esClient.indices.create({
        index: ES_INDICES.MESSAGES,
        ...MESSAGE_INDEX_SETTINGS
      });
      info(`Created ${ES_INDICES.MESSAGES} index`);
    }
  } catch (err) {
    error('Failed to initialize Elasticsearch indices', { error: err, code: ERROR_CODES.DATABASE_ERROR });
    throw err;
  }
};

// Requirement: Search Infrastructure - Search configuration for different indices
const getSearchConfig = (indexName: string): object => {
  const baseConfig = {
    min_score: 0.3,
    track_scores: true,
    track_total_hits: true
  };

  switch (indexName) {
    case ES_INDICES.FURNITURE:
      return {
        ...baseConfig,
        highlight: {
          fields: {
            title: {},
            description: {}
          }
        },
        sort: [
          { _score: 'desc' },
          { created_at: 'desc' }
        ]
      };

    case ES_INDICES.USERS:
      return {
        ...baseConfig,
        highlight: {
          fields: {
            full_name: {}
          }
        }
      };

    case ES_INDICES.MESSAGES:
      return {
        ...baseConfig,
        sort: [
          { sent_at: 'desc' }
        ]
      };

    default:
      return baseConfig;
  }
};

export {
  createElasticsearchClient as default,
  initializeIndices,
  getSearchConfig,
  ES_INDICES
};