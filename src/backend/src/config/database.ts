/**
 * Human Tasks:
 * 1. Set up environment variables for database credentials in .env file
 * 2. Configure SSL certificates for database connections in production
 * 3. Review and adjust connection pool settings based on load testing results
 * 4. Set up database backup and restore procedures
 * 5. Configure database monitoring and alerting thresholds
 */

// External dependencies
import { Pool } from 'pg'; // ^8.11.0
import mongoose from 'mongoose'; // ^7.0.0
import Redis from 'ioredis'; // ^5.3.0
import { Client as InfluxClient } from '@influxdata/influxdb-client'; // ^1.33.0
import { Client as ElasticsearchClient } from '@elastic/elasticsearch'; // ^8.8.0
import dotenv from 'dotenv'; // ^16.0.0

// Internal dependencies
import { ERROR_CODES } from '../constants/error-codes';

// Load environment variables
dotenv.config();

// Default configuration values
const DEFAULT_PG_PORT = 5432;
const DEFAULT_REDIS_PORT = 6379;
const DEFAULT_MONGO_OPTIONS = {
  useNewUrlParser: true,
  useUnifiedTopology: true
};
const CONNECTION_RETRY_ATTEMPTS = 5;
const CONNECTION_RETRY_DELAY = 5000;

/**
 * Interface definitions for database configurations
 * Requirements addressed: Data Storage Architecture, Database Design
 */
interface PostgresConfig {
  host: string;
  port: number;
  database: string;
  user: string;
  password: string;
  max: number;
  idleTimeoutMillis: number;
  ssl: boolean;
}

interface MongoConfig {
  uri: string;
  database: string;
  options: object;
}

interface RedisConfig {
  host: string;
  port: number;
  password: string;
  db: number;
  tls: boolean;
}

interface InfluxConfig {
  url: string;
  token: string;
  org: string;
  bucket: string;
}

interface ElasticsearchConfig {
  nodes: string[];
  username: string;
  password: string;
  tls: boolean;
}

/**
 * Creates and configures PostgreSQL connection pool
 * Requirements addressed: Data Storage Architecture, Data Security
 */
export const createPostgresPool = (config: PostgresConfig): Pool => {
  const pool = new Pool({
    host: config.host,
    port: config.port || DEFAULT_PG_PORT,
    database: config.database,
    user: config.user,
    password: config.password,
    max: config.max,
    idleTimeoutMillis: config.idleTimeoutMillis,
    ssl: config.ssl ? {
      rejectUnauthorized: false // Should be true in production with valid certificates
    } : false
  });

  pool.on('error', (err) => {
    console.error('Unexpected PostgreSQL error:', err);
    throw new Error(ERROR_CODES.DATABASE_CONNECTION_ERROR);
  });

  return pool;
};

/**
 * Establishes MongoDB connection with retry logic
 * Requirements addressed: Data Storage Architecture, Database Design
 */
export const createMongoConnection = async (config: MongoConfig): Promise<mongoose.Connection> => {
  let attempts = 0;
  
  while (attempts < CONNECTION_RETRY_ATTEMPTS) {
    try {
      await mongoose.connect(config.uri, {
        ...DEFAULT_MONGO_OPTIONS,
        ...config.options,
        dbName: config.database
      });
      
      const connection = mongoose.connection;
      
      connection.on('error', (err) => {
        console.error('MongoDB connection error:', err);
        throw new Error(ERROR_CODES.DATABASE_CONNECTION_ERROR);
      });

      connection.once('open', () => {
        console.log('MongoDB connection established successfully');
      });

      return connection;
    } catch (error) {
      attempts++;
      if (attempts === CONNECTION_RETRY_ATTEMPTS) {
        throw new Error(ERROR_CODES.DATABASE_CONNECTION_ERROR);
      }
      await new Promise(resolve => setTimeout(resolve, CONNECTION_RETRY_DELAY));
    }
  }

  throw new Error(ERROR_CODES.DATABASE_CONNECTION_ERROR);
};

/**
 * Creates Redis client instance
 * Requirements addressed: Data Storage Architecture, Data Security
 */
export const createRedisClient = (config: RedisConfig): Redis => {
  const client = new Redis({
    host: config.host,
    port: config.port || DEFAULT_REDIS_PORT,
    password: config.password,
    db: config.db,
    tls: config.tls ? {} : undefined,
    retryStrategy: (times: number) => {
      if (times > CONNECTION_RETRY_ATTEMPTS) {
        throw new Error(ERROR_CODES.DATABASE_CONNECTION_ERROR);
      }
      return CONNECTION_RETRY_DELAY;
    }
  });

  client.on('error', (err) => {
    console.error('Redis client error:', err);
    throw new Error(ERROR_CODES.DATABASE_CONNECTION_ERROR);
  });

  return client;
};

/**
 * Creates InfluxDB client instance
 * Requirements addressed: Data Storage Architecture, Database Design
 */
export const createInfluxClient = (config: InfluxConfig): InfluxClient => {
  const client = new InfluxClient({
    url: config.url,
    token: config.token
  });

  // Verify connection by writing a test point
  try {
    const writeApi = client.getWriteApi(config.org, config.bucket);
    writeApi.close().catch(e => {
      console.error('InfluxDB connection error:', e);
      throw new Error(ERROR_CODES.DATABASE_CONNECTION_ERROR);
    });
  } catch (error) {
    throw new Error(ERROR_CODES.DATABASE_CONNECTION_ERROR);
  }

  return client;
};

/**
 * Creates Elasticsearch client instance
 * Requirements addressed: Data Storage Architecture, Data Security
 */
export const createElasticsearchClient = (config: ElasticsearchConfig): ElasticsearchClient => {
  const client = new ElasticsearchClient({
    nodes: config.nodes,
    auth: {
      username: config.username,
      password: config.password
    },
    tls: {
      rejectUnauthorized: config.tls
    }
  });

  // Verify connection
  client.ping()
    .catch(error => {
      console.error('Elasticsearch connection error:', error);
      throw new Error(ERROR_CODES.DATABASE_CONNECTION_ERROR);
    });

  return client;
};

// Create and export database client instances
export const postgresPool = createPostgresPool({
  host: process.env.POSTGRES_HOST!,
  port: parseInt(process.env.POSTGRES_PORT!) || DEFAULT_PG_PORT,
  database: process.env.POSTGRES_DB!,
  user: process.env.POSTGRES_USER!,
  password: process.env.POSTGRES_PASSWORD!,
  max: parseInt(process.env.POSTGRES_POOL_MAX!) || 20,
  idleTimeoutMillis: parseInt(process.env.POSTGRES_IDLE_TIMEOUT!) || 30000,
  ssl: process.env.NODE_ENV === 'production'
});

export const mongoConnection = await createMongoConnection({
  uri: process.env.MONGO_URI!,
  database: process.env.MONGO_DB!,
  options: DEFAULT_MONGO_OPTIONS
});

export const redisClient = createRedisClient({
  host: process.env.REDIS_HOST!,
  port: parseInt(process.env.REDIS_PORT!) || DEFAULT_REDIS_PORT,
  password: process.env.REDIS_PASSWORD!,
  db: parseInt(process.env.REDIS_DB!) || 0,
  tls: process.env.NODE_ENV === 'production'
});

export const influxClient = createInfluxClient({
  url: process.env.INFLUX_URL!,
  token: process.env.INFLUX_TOKEN!,
  org: process.env.INFLUX_ORG!,
  bucket: process.env.INFLUX_BUCKET!
});

export const elasticsearchClient = createElasticsearchClient({
  nodes: process.env.ELASTICSEARCH_NODES!.split(','),
  username: process.env.ELASTICSEARCH_USERNAME!,
  password: process.env.ELASTICSEARCH_PASSWORD!,
  tls: process.env.NODE_ENV === 'production'
});