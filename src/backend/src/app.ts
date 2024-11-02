/**
 * Human Tasks:
 * 1. Configure environment variables in .env file
 * 2. Set up SSL certificates for production
 * 3. Configure monitoring and alerting thresholds
 * 4. Review and adjust rate limiting settings
 * 5. Set up logging aggregation service
 * 6. Configure CORS allowed origins for production
 */

// Third-party imports with versions
import express, { Express } from 'express'; // ^4.18.2
import cors from 'cors'; // ^2.8.5
import helmet from 'helmet'; // ^7.0.0
import compression from 'compression'; // ^1.7.4
import morgan from 'morgan'; // ^1.10.0
import dotenv from 'dotenv'; // ^16.0.0

// Internal imports
import {
  postgresPool,
  mongoConnection,
  redisClient,
  elasticsearchClient
} from './config/database';
import { s3Client, cloudFrontClient } from './config/aws';
import errorHandler from './middleware/error.middleware';
import { authenticateRequest } from './middleware/auth.middleware';
import furnitureRouter from './routes/furniture.routes';

// Load environment variables
dotenv.config();

// Initialize Express application
const app: Express = express();

/**
 * Initialize and configure Express middleware stack
 * Requirements addressed:
 * - Security Architecture (3.6)
 * - System Health Metrics (Appendix D)
 */
const initializeMiddleware = (app: Express): void => {
  // Security headers middleware
  app.use(helmet());

  // CORS configuration
  app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    exposedHeaders: ['X-Total-Count'],
    credentials: true,
    maxAge: 86400 // 24 hours
  }));

  // Response compression
  app.use(compression());

  // Request logging
  app.use(morgan('combined'));

  // Body parsing middleware
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Authentication middleware for protected routes
  app.use('/api', authenticateRequest);
};

/**
 * Register all application routes
 * Requirements addressed:
 * - Backend Services (1.2)
 * - API Design (6.3)
 */
const initializeRoutes = (app: Express): void => {
  // Health check endpoint
  app.get('/health', (req, res) => {
    res.status(200).json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        postgres: postgresPool.totalCount > 0,
        mongodb: mongoConnection.readyState === 1,
        redis: redisClient.status === 'ready',
        elasticsearch: elasticsearchClient.ping(),
        s3: !!s3Client,
        cloudfront: !!cloudFrontClient
      }
    });
  });

  // API routes
  app.use('/api/v1/furniture', furnitureRouter);

  // 404 handler for unmatched routes
  app.use((req, res) => {
    res.status(404).json({
      error: 'NOT_FOUND',
      message: 'The requested resource was not found'
    });
  });
};

/**
 * Set up global error handling
 * Requirements addressed:
 * - Error Handling (Appendix A.3)
 * - System Health Metrics (Appendix D)
 */
const initializeErrorHandling = (app: Express): void => {
  // Register global error handler
  app.use(errorHandler);

  // Handle uncaught exceptions
  process.on('uncaughtException', (error: Error) => {
    console.error('Uncaught Exception:', error);
    process.exit(1);
  });

  // Handle unhandled promise rejections
  process.on('unhandledRejection', (reason: any) => {
    console.error('Unhandled Rejection:', reason);
    process.exit(1);
  });
};

/**
 * Initialize all application components
 * Requirements addressed:
 * - System Architecture (3.1)
 * - Component Architecture (4.1)
 */
const initializeApp = async (): Promise<Express> => {
  try {
    // Initialize middleware
    initializeMiddleware(app);

    // Initialize routes
    initializeRoutes(app);

    // Initialize error handling
    initializeErrorHandling(app);

    // Verify database connections
    await Promise.all([
      postgresPool.query('SELECT 1'),
      mongoConnection.readyState === 1,
      redisClient.ping(),
      elasticsearchClient.ping()
    ]);

    console.log('All services initialized successfully');
    return app;
  } catch (error) {
    console.error('Failed to initialize application:', error);
    throw error;
  }
};

// Initialize the application
const app = await initializeApp();

// Export configured Express application
export default app;