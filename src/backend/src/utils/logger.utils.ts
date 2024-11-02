// Human Tasks:
// 1. Set up AWS CloudWatch access credentials in environment variables
// 2. Configure LOG_LEVEL in environment for different environments (development/staging/production)
// 3. Set up appropriate CloudWatch Log Groups and Streams in AWS Console
// 4. Verify AWS IAM roles have necessary CloudWatch Logs permissions
// 5. Set up log rotation policies in CloudWatch

// Third-party imports with versions
import winston from 'winston'; // ^3.8.0
import WinstonCloudWatch from 'winston-cloudwatch'; // ^3.1.0
import { CloudWatchLogsClient } from '@aws-sdk/client-cloudwatch-logs'; // ^3.x

// Global configuration from environment variables
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const LOG_GROUP = process.env.CLOUDWATCH_LOG_GROUP || 'founditure-logs';
const LOG_STREAM = process.env.CLOUDWATCH_LOG_STREAM || 'backend-logs';

// Requirement: 3.2.2 Backend Service Architecture/Support Services/Logging
// Implements structured logging format for consistent log entries
const formatLogMessage = (info: winston.LogEntry): string => {
  const {
    level,
    message,
    timestamp = new Date().toISOString(),
    correlationId,
    service = 'founditure-backend',
    ...metadata
  } = info;

  return JSON.stringify({
    timestamp,
    level,
    service,
    correlationId,
    message,
    ...metadata
  });
};

// Requirement: 8.2 Cloud Services/CloudWatch
// Creates CloudWatch transport with proper AWS configuration
const createCloudWatchTransport = (config: any): WinstonCloudWatch => {
  const cloudWatchClient = new CloudWatchLogsClient({
    region: process.env.AWS_REGION || 'us-east-1',
    maxRetries: 3
  });

  return new WinstonCloudWatch({
    cloudWatchClient,
    logGroupName: LOG_GROUP,
    logStreamName: LOG_STREAM,
    messageFormatter: formatLogMessage,
    retentionInDays: 14,
    batchSize: 20,
    awsOptions: {
      credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || ''
      }
    },
    ...config
  });
};

// Requirement: 7.3.2 Security Monitoring
// Creates and configures the Winston logger instance with security logging capabilities
const createLogger = (options: any = {}): winston.Logger => {
  const transports: winston.transport[] = [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.timestamp(),
        winston.format.printf(formatLogMessage)
      )
    })
  ];

  // Add CloudWatch transport in production environment
  if (process.env.NODE_ENV === 'production') {
    transports.push(createCloudWatchTransport(options.cloudWatch || {}));
  }

  return winston.createLogger({
    level: LOG_LEVEL,
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.metadata()
    ),
    defaultMeta: {
      service: 'founditure-backend',
      environment: process.env.NODE_ENV
    },
    transports,
    exitOnError: false
  });
};

// Create default logger instance
const logger = createLogger();

// Export logger functions and factory
export {
  logger,
  createLogger
};

// Export individual log level functions for convenience
export const error = logger.error.bind(logger);
export const warn = logger.warn.bind(logger);
export const info = logger.info.bind(logger);
export const debug = logger.debug.bind(logger);
export const verbose = logger.verbose.bind(logger);