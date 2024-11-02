/**
 * Human Tasks:
 * 1. Configure WebSocket event handlers for real-time message delivery
 * 2. Set up rate limiting rules for message endpoints
 * 3. Configure content moderation thresholds in environment variables
 * 4. Set up monitoring for message delivery performance
 * 5. Configure message retention policies in production
 */

// Third-party imports with versions
import express, { Router } from 'express'; // ^4.18.2

// Internal imports
import MessageController from '../controllers/message.controller';
import { authenticateRequest } from '../middleware/auth.middleware';
import { validateMessageContent, validateMessageThread } from '../validators/message.validator';

/**
 * Configures and returns the message router with all message-related endpoints
 * Addresses requirements:
 * - Real-time messaging system (1.2 Scope/Core System Components)
 * - Content moderation (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 */
const configureMessageRoutes = (messageController: MessageController): Router => {
  const router = express.Router();

  /**
   * POST /api/messages/send
   * Send a new message
   * Addresses requirements:
   * - Real-time messaging system
   * - Content moderation
   */
  router.post(
    '/send',
    authenticateRequest,
    async (req, res) => await messageController.sendMessage(req, res)
  );

  /**
   * GET /api/messages/thread/:threadId
   * Get messages in a thread
   * Addresses requirements:
   * - Real-time messaging system
   * - Privacy controls
   */
  router.get(
    '/thread/:threadId',
    authenticateRequest,
    async (req, res) => await messageController.getMessageThread(req, res)
  );

  /**
   * PUT /api/messages/:messageId/read
   * Mark a message as read
   * Addresses requirement:
   * - Real-time messaging system
   */
  router.put(
    '/:messageId/read',
    authenticateRequest,
    async (req, res) => await messageController.markMessageAsRead(req, res)
  );

  /**
   * GET /api/messages/threads
   * Get all message threads for user
   * Addresses requirements:
   * - Real-time messaging system
   * - Privacy controls
   */
  router.get(
    '/threads',
    authenticateRequest,
    async (req, res) => await messageController.getUserThreads(req, res)
  );

  /**
   * DELETE /api/messages/:messageId
   * Delete a message
   * Addresses requirements:
   * - Content moderation
   * - Privacy controls
   */
  router.delete(
    '/:messageId',
    authenticateRequest,
    async (req, res) => await messageController.deleteMessage(req, res)
  );

  return router;
};

// Export configured message router
const messageRouter = configureMessageRoutes(new MessageController(null));
export default messageRouter;