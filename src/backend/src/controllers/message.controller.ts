/**
 * Human Tasks:
 * 1. Configure WebSocket event handlers in the application layer
 * 2. Set up message rate limiting rules
 * 3. Configure content moderation thresholds
 * 4. Set up monitoring for message delivery rates
 * 5. Configure message retention policies
 */

// Third-party imports with versions
import { Request, Response } from 'express'; // ^4.18.2
import httpStatus from 'http-status'; // ^1.6.2

// Internal imports
import MessageService from '../services/message.service';
import { 
  IMessage, 
  MessageType, 
  MessageStatus, 
  IMessageThread 
} from '../interfaces/message.interface';
import { 
  validateMessageContent, 
  validateMessageThread, 
  validateMessageAttachment 
} from '../validators/message.validator';
import { 
  authenticateRequest, 
  authorizeRoles 
} from '../middleware/auth.middleware';

/**
 * Controller handling message-related HTTP endpoints
 * Addresses requirements:
 * - Real-time messaging system (1.2 Scope/Core System Components)
 * - Content moderation (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 */
class MessageController {
  private messageService: MessageService;

  constructor(messageService: MessageService) {
    this.messageService = messageService;
  }

  /**
   * Handles sending a new message
   * Addresses requirements:
   * - Real-time messaging system
   * - Content moderation
   */
  @authenticateRequest
  public async sendMessage(req: Request, res: Response): Promise<Response> {
    try {
      const { content, receiverId, furnitureId, type = MessageType.TEXT } = req.body;
      const senderId = req.user.id;

      // Validate message content
      const contentValidation = validateMessageContent(content);
      if (!contentValidation.isValid) {
        return res.status(httpStatus.BAD_REQUEST).json({
          error: contentValidation.errorCode,
          message: contentValidation.errorMessage
        });
      }

      // Validate thread parameters
      const threadValidation = validateMessageThread(senderId, receiverId, furnitureId);
      if (!threadValidation.isValid) {
        return res.status(httpStatus.BAD_REQUEST).json({
          error: threadValidation.errorCode,
          message: threadValidation.errorMessage
        });
      }

      // Handle attachments if present
      if (req.body.attachment) {
        const attachmentValidation = validateMessageAttachment(req.body.attachment);
        if (!attachmentValidation.isValid) {
          return res.status(httpStatus.BAD_REQUEST).json({
            error: attachmentValidation.errorCode,
            message: attachmentValidation.errorMessage
          });
        }
      }

      // Create message object
      const messageData: IMessage = {
        id: undefined, // Will be set by service
        senderId,
        receiverId,
        furnitureId,
        content,
        type,
        status: MessageStatus.SENT,
        isRead: false,
        readAt: undefined,
        createdAt: new Date(),
        updatedAt: new Date()
      };

      // Send message through service
      const createdMessage = await this.messageService.sendMessage(messageData);

      return res.status(httpStatus.CREATED).json(createdMessage);
    } catch (error) {
      return res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
        error: 'MESSAGE_SEND_FAILED',
        message: error.message
      });
    }
  }

  /**
   * Retrieves a message thread between users
   * Addresses requirements:
   * - Real-time messaging system
   * - Privacy controls
   */
  @authenticateRequest
  public async getMessageThread(req: Request, res: Response): Promise<Response> {
    try {
      const { otherUserId, furnitureId } = req.params;
      const userId = req.user.id;

      // Validate thread parameters
      const threadValidation = validateMessageThread(userId, otherUserId, furnitureId);
      if (!threadValidation.isValid) {
        return res.status(httpStatus.BAD_REQUEST).json({
          error: threadValidation.errorCode,
          message: threadValidation.errorMessage
        });
      }

      // Retrieve thread
      const thread = await this.messageService.getMessageThread(
        userId,
        otherUserId,
        furnitureId
      );

      return res.status(httpStatus.OK).json(thread);
    } catch (error) {
      return res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
        error: 'MESSAGE_THREAD_RETRIEVAL_FAILED',
        message: error.message
      });
    }
  }

  /**
   * Marks a message as read
   * Addresses requirement: Real-time messaging system
   */
  @authenticateRequest
  public async markMessageAsRead(req: Request, res: Response): Promise<Response> {
    try {
      const { messageId } = req.params;
      const userId = req.user.id;

      // Mark message as read
      const updatedMessage = await this.messageService.markMessageAsRead(messageId, userId);

      return res.status(httpStatus.OK).json(updatedMessage);
    } catch (error) {
      return res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
        error: 'MESSAGE_UPDATE_FAILED',
        message: error.message
      });
    }
  }

  /**
   * Retrieves all message threads for a user
   * Addresses requirements:
   * - Real-time messaging system
   * - Privacy controls
   */
  @authenticateRequest
  public async getUserThreads(req: Request, res: Response): Promise<Response> {
    try {
      const userId = req.user.id;

      // Retrieve user threads
      const threads = await this.messageService.getUserThreads(userId);

      return res.status(httpStatus.OK).json(threads);
    } catch (error) {
      return res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
        error: 'THREAD_RETRIEVAL_FAILED',
        message: error.message
      });
    }
  }

  /**
   * Deletes a message
   * Addresses requirements:
   * - Content moderation
   * - Privacy controls
   */
  @authenticateRequest
  public async deleteMessage(req: Request, res: Response): Promise<Response> {
    try {
      const { messageId } = req.params;
      const userId = req.user.id;

      // Delete message
      const success = await this.messageService.deleteMessage(messageId, userId);

      if (!success) {
        return res.status(httpStatus.NOT_FOUND).json({
          error: 'MESSAGE_NOT_FOUND',
          message: 'Message not found or already deleted'
        });
      }

      return res.status(httpStatus.OK).json({
        message: 'Message deleted successfully'
      });
    } catch (error) {
      return res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
        error: 'MESSAGE_DELETION_FAILED',
        message: error.message
      });
    }
  }
}

export default MessageController;