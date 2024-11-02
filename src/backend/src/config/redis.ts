// Human Tasks:
// 1. Set up Redis cluster nodes in production environment
// 2. Configure Redis password in environment variables
// 3. Set up Redis monitoring alerts in CloudWatch
// 4. Configure Redis backup strategy
// 5. Set up Redis cluster failover testing procedure

// Third-party imports with versions
import Redis from 'ioredis'; // ^5.3.0

// Internal imports
import { error, warn, info } from '../utils/logger.utils';

// Environment variables with defaults
const REDIS_HOST = process.env.REDIS_HOST || 'localhost';
const REDIS_PORT = parseInt(process.env.REDIS_PORT || '6379');
const REDIS_PASSWORD = process.env.REDIS_PASSWORD;
const REDIS_DB = parseInt(process.env.REDIS_DB || '0');
const REDIS_CLUSTER_ENABLED = process.env.REDIS_CLUSTER_ENABLED === 'true';

// Requirement: 3.3.3 Data Storage/Cache Layer
// Validates Redis configuration settings and connection parameters
const validateRedisConfig = (): boolean => {
  try {
    // Validate host
    if (!REDIS_HOST) {
      error('Redis host configuration is missing');
      return false;
    }

    // Validate port range
    if (REDIS_PORT < 1 || REDIS_PORT > 65535) {
      error('Redis port is invalid');
      return false;
    }

    // Validate database index
    if (REDIS_DB < 0) {
      error('Redis database index must be non-negative');
      return false;
    }

    // Warn if password is not set in production
    if (process.env.NODE_ENV === 'production' && !REDIS_PASSWORD) {
      warn('Redis password is not set in production environment');
    }

    info('Redis configuration validation successful');
    return true;
  } catch (err) {
    error('Redis configuration validation failed', { error: err });
    return false;
  }
};

// Requirement: 3.5 Scalability Architecture/Cache Layer
// Configures event handlers for Redis client monitoring
const configureRedisEvents = (client: Redis): void => {
  client.on('connect', () => {
    info('Redis client connecting');
  });

  client.on('ready', () => {
    info('Redis client connected and ready');
  });

  client.on('error', (err) => {
    error('Redis client error', { error: err });
  });

  client.on('close', () => {
    warn('Redis client connection closed');
  });

  client.on('reconnecting', (delay) => {
    info('Redis client reconnecting', { delay });
  });

  client.on('end', () => {
    warn('Redis client connection ended');
  });
};

// Requirement: 3.3.3 Data Storage/Cache Layer
// Creates and configures a Redis client instance with appropriate cluster/standalone settings
const createRedisClient = (): Redis => {
  let client: Redis;

  if (REDIS_CLUSTER_ENABLED) {
    // Cluster mode configuration
    client = new Redis.Cluster(
      [
        {
          host: REDIS_HOST,
          port: REDIS_PORT
        }
      ],
      {
        redisOptions: {
          password: REDIS_PASSWORD,
          db: REDIS_DB,
          enableReadyCheck: true,
          maxRetriesPerRequest: 3,
          retryStrategy: (times: number) => {
            return Math.min(times * 50, 2000);
          }
        },
        clusterRetryStrategy: (times: number) => {
          return Math.min(times * 100, 3000);
        },
        scaleReads: 'slave',
        natMap: process.env.REDIS_NAT_MAP ? JSON.parse(process.env.REDIS_NAT_MAP) : undefined
      }
    );
  } else {
    // Standalone mode configuration
    client = new Redis({
      host: REDIS_HOST,
      port: REDIS_PORT,
      password: REDIS_PASSWORD,
      db: REDIS_DB,
      enableReadyCheck: true,
      maxRetriesPerRequest: 3,
      retryStrategy: (times: number) => {
        return Math.min(times * 50, 2000);
      },
      lazyConnect: true,
      connectTimeout: 10000,
      disconnectTimeout: 2000,
      commandTimeout: 5000,
      keepAlive: 10000,
      enableOfflineQueue: true,
      maxLoadingRetryTime: 5000
    });
  }

  // Configure event handlers
  configureRedisEvents(client);

  return client;
};

// Requirement: 1.1 System Overview/Real-time Features
// Create and export the Redis client instance
const redisClient = createRedisClient();

// Export the client and validation utility
export default redisClient;
export { validateRedisConfig };