// Human Tasks:
// 1. Configure Redis rate limit keys TTL in environment variables
// 2. Set up monitoring alerts for rate limit violations
// 3. Configure rate limit thresholds per environment
// 4. Set up rate limit bypass for trusted IPs if needed
// 5. Configure custom rate limit rules for specific endpoints

// Third-party imports with versions
import { Request, Response, NextFunction } from 'express'; // ^4.18.0
import ms from 'ms'; // ^2.1.3

// Internal imports
import redisClient from '../config/redis';
import { logger } from '../utils/logger.utils';

// Default rate limit configuration
const DEFAULT_WINDOW_MS = 60 * 1000; // 1 minute
const DEFAULT_MAX_REQUESTS = 100;

// Rate limiter options interface
interface RateLimiterOptions {
  windowMs?: number | string;
  max?: number;
  keyPrefix?: string;
  handler?: (req: Request, res: Response) => void;
  skipFailedRequests?: boolean;
  skipSuccessfulRequests?: boolean;
}

// Requirement: 7.3.3 Security Controls/Rate limiting per user/IP
// Creates a rate limiter middleware instance with configurable options
export const createRateLimiter = (options: RateLimiterOptions = {}) => {
  // Parse and validate options
  const windowMs = typeof options.windowMs === 'string' 
    ? ms(options.windowMs) 
    : (options.windowMs || DEFAULT_WINDOW_MS);
  const max = options.max || DEFAULT_MAX_REQUESTS;
  const keyPrefix = options.keyPrefix || 'rate-limit:';

  // Requirement: 7.3.1 Network Security/API security measures including rate limiting
  // Return middleware function
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const identifier = await getClientIdentifier(req);
      const key = `${keyPrefix}${identifier}`;
      
      // Get current window start time
      const now = Date.now();
      const windowStart = now - windowMs;
      
      // Clean up old requests and add current request
      const multi = redisClient.multi();
      multi.zremrangebyscore(key, 0, windowStart);
      multi.zadd(key, now, `${now}`);
      multi.zcard(key);
      multi.pexpire(key, windowMs);
      
      const [, , requestCount] = await multi.exec() as [any, any, [null | Error, number]];
      
      // Check if request count exceeds limit
      if (requestCount[1] > max) {
        logger.warn('Rate limit exceeded', {
          identifier,
          requestCount: requestCount[1],
          limit: max,
          windowMs
        });

        // Add rate limit headers
        res.setHeader('X-RateLimit-Limit', max);
        res.setHeader('X-RateLimit-Remaining', 0);
        res.setHeader('X-RateLimit-Reset', Math.ceil((windowStart + windowMs) / 1000));
        
        // Use custom handler or default response
        if (options.handler) {
          return options.handler(req, res);
        }
        
        res.status(429).json({
          error: 'Too Many Requests',
          message: 'Rate limit exceeded. Please try again later.',
          retryAfter: Math.ceil(windowMs / 1000)
        });
        return;
      }

      // Add rate limit headers for successful requests
      res.setHeader('X-RateLimit-Limit', max);
      res.setHeader('X-RateLimit-Remaining', Math.max(0, max - requestCount[1]));
      res.setHeader('X-RateLimit-Reset', Math.ceil((windowStart + windowMs) / 1000));

      // Requirement: 7.3.3 Security Controls/DDoS protection through rate limiting
      // Skip counting the request if configured
      if (
        (options.skipSuccessfulRequests && res.statusCode < 400) ||
        (options.skipFailedRequests && res.statusCode >= 400)
      ) {
        return next();
      }

      next();
    } catch (error) {
      logger.error('Rate limit middleware error', { error });
      // Fail open - allow request in case of rate limit errors
      next();
    }
  };
};

// Requirement: 7.3.1 Network Security/API security measures including rate limiting
// Extracts unique client identifier from request
const getClientIdentifier = async (req: Request): Promise<string> => {
  // Use user ID if authenticated
  if (req.user && req.user.id) {
    return `user:${req.user.id}`;
  }

  // Fall back to IP address
  const ip = req.headers['x-forwarded-for'] || 
    req.connection.remoteAddress || 
    req.socket.remoteAddress;

  return `ip:${ip}`;
};

// Export default rate limiter with standard configuration
export default createRateLimiter();