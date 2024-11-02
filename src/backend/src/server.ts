/**
 * Human Tasks:
 * 1. Configure environment variables in .env file:
 *    - PORT: Server port (default: 3000)
 *    - NODE_ENV: Environment (development/staging/production)
 *    - CLUSTER_ENABLED: Enable/disable clustering (true/false)
 *    - NUM_WORKERS: Number of worker processes
 * 2. Set up SSL certificates for production environment
 * 3. Configure monitoring and alerting thresholds
 * 4. Set up log aggregation service
 * 5. Review and adjust auto-scaling parameters
 */

// Third-party imports with versions
import http from 'http'; // built-in
import dotenv from 'dotenv'; // ^16.0.0
import cluster from 'cluster'; // built-in
import os from 'os'; // built-in

// Internal imports
import app from './app';
import createWebSocketServer from './config/websocket';
import { logger } from './utils/logger.utils';

// Load environment variables
dotenv.config();

// Global constants from environment
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';
const CLUSTER_ENABLED = process.env.CLUSTER_ENABLED === 'true';
const NUM_WORKERS = process.env.NUM_WORKERS || os.cpus().length;

/**
 * Initializes and starts the HTTP and WebSocket servers
 * Requirements addressed:
 * - Backend Services (1.2 Scope/Core System Components)
 * - System Architecture (3.1 High-Level Architecture Overview)
 */
const startServer = async (): Promise<void> => {
  try {
    // Create HTTP server instance
    const server = http.createServer(app);

    // Initialize WebSocket server
    const wsServer = createWebSocketServer(server);

    // Start listening on configured port
    server.listen(PORT, () => {
      logger.info(`Server running in ${NODE_ENV} mode on port ${PORT}`);
      logger.info(`WebSocket server initialized`);
    });

    // Handle server errors
    server.on('error', (error: Error) => {
      logger.error('Server error:', error);
      process.exit(1);
    });

    // Handle client errors
    server.on('clientError', (error: Error) => {
      logger.error('Client error:', error);
    });

    // Configure graceful shutdown
    const handleGracefulShutdown = async () => {
      logger.info('Initiating graceful shutdown...');

      // Close HTTP server
      server.close(() => {
        logger.info('HTTP server closed');
      });

      // Close WebSocket server
      wsServer.close(() => {
        logger.info('WebSocket server closed');
      });

      // Allow ongoing requests to complete (30 second timeout)
      setTimeout(() => {
        logger.info('Forcing process exit');
        process.exit(1);
      }, 30000);
    };

    // Register shutdown handlers
    process.on('SIGTERM', handleGracefulShutdown);
    process.on('SIGINT', handleGracefulShutdown);

  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

/**
 * Sets up worker processes for clustering if enabled
 * Requirements addressed:
 * - Scalability Architecture (3.5 Scalability Architecture)
 */
const initializeCluster = (): void => {
  if (cluster.isPrimary && CLUSTER_ENABLED) {
    logger.info(`Primary ${process.pid} is running`);
    logger.info(`Starting ${NUM_WORKERS} workers...`);

    // Fork workers
    for (let i = 0; i < NUM_WORKERS; i++) {
      cluster.fork();
    }

    // Handle worker errors
    cluster.on('exit', (worker, code, signal) => {
      logger.error(`Worker ${worker.process.pid} died. Code: ${code}, Signal: ${signal}`);
      logger.info('Starting new worker...');
      cluster.fork();
    });

    cluster.on('error', (error) => {
      logger.error('Cluster error:', error);
    });

    cluster.on('disconnect', (worker) => {
      logger.warn(`Worker ${worker.process.pid} disconnected`);
    });

  } else {
    // Start server in worker process or non-clustered mode
    startServer().catch((error) => {
      logger.error('Failed to start server in worker:', error);
      process.exit(1);
    });
  }
};

// Handle uncaught exceptions and unhandled rejections
process.on('uncaughtException', (error: Error) => {
  logger.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason: any) => {
  logger.error('Unhandled Rejection:', reason);
  process.exit(1);
});

// Initialize server with clustering support
initializeCluster();