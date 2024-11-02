/**
 * Human Tasks:
 * 1. Configure MongoDB indexes for message queries
 * 2. Set up WebSocket event handlers in the application layer
 * 3. Configure content moderation rules and thresholds
 * 4. Set up monitoring for message delivery rates and latency
 * 5. Configure message retention policies
 */

// Third-party imports with versions
import mongoose from 'mongoose'; // ^7.x

// Internal imports
import MessageModel, { MessageDocument } from '../models/message.model';
import { 
  IMessage, 
  MessageType, 
  MessageStatus, 
  IMessageThread, 
  MessageThreadStatus 
} from '../interfaces/message.interface';
import WebSocketService from './websocket.service';
import { error } from '../utils/logger.utils';

/**
 * Service class handling all message-related operations
 * Addresses requirements:
 * - Real-time messaging system (1.2 Scope/Core System Components)
 * - Content moderation (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 */
class MessageService {
  private webSocketService: WebSocketService;

  constructor(webSocketService: WebSocketService) {
    this.webSocketService = webSocketService;
  }

  /**
   * Sends a new message and handles real-time delivery
   * Addresses requirement: Real-time messaging system
   */
  public async sendMessage(messageData: IMessage): Promise<IMessage> {
    try {
      // Validate message content
      this.validateMessageContent(messageData.content);

      // Create new message document
      const message = new MessageModel({
        senderId: messageData.senderId,
        receiverId: messageData.receiverId,
        furnitureId: messageData.furnitureId,
        content: messageData.content,
        type: messageData.type || MessageType.TEXT,
        status: MessageStatus.SENT,
        isRead: false
      });

      // Save message to database
      const savedMessage = await message.save();

      // Emit real-time update through WebSocket
      this.webSocketService.sendToUser(messageData.receiverId, 'new_message', {
        message: savedMessage,
        threadId: await this.getThreadId(savedMessage.senderId, savedMessage.receiverId, savedMessage.furnitureId)
      });

      // Update message thread
      await this.updateMessageThread(savedMessage);

      return savedMessage.toObject();
    } catch (err) {
      error('Error sending message:', err);
      throw err;
    }
  }

  /**
   * Retrieves a message thread between users for a furniture item
   * Addresses requirements: Real-time messaging system, Privacy controls
   */
  public async getMessageThread(
    userId: string,
    otherUserId: string,
    furnitureId: string
  ): Promise<IMessageThread> {
    try {
      // Validate user access to thread
      await this.validateThreadAccess(userId, otherUserId, furnitureId);

      // Query messages between users
      const messages = await MessageModel.find({
        $or: [
          { senderId: userId, receiverId: otherUserId, furnitureId },
          { senderId: otherUserId, receiverId: userId, furnitureId }
        ]
      })
      .sort({ createdAt: -1 })
      .limit(50);

      // Calculate thread metadata
      const unreadCount = await this.getUnreadCount(userId, otherUserId, furnitureId);
      const lastMessage = messages[0];

      // Construct thread object
      const thread: IMessageThread = {
        id: await this.getThreadId(userId, otherUserId, furnitureId),
        participantIds: [userId, otherUserId],
        furnitureId,
        status: MessageThreadStatus.ACTIVE,
        lastMessageAt: lastMessage?.createdAt || new Date(),
        unreadCount,
        createdAt: messages[messages.length - 1]?.createdAt || new Date(),
        updatedAt: new Date()
      };

      return thread;
    } catch (err) {
      error('Error retrieving message thread:', err);
      throw err;
    }
  }

  /**
   * Marks a message as read and updates thread metadata
   * Addresses requirement: Real-time messaging system
   */
  public async markMessageAsRead(messageId: string, userId: string): Promise<IMessage> {
    try {
      // Find and validate message
      const message = await MessageModel.findById(messageId);
      if (!message || message.receiverId.toString() !== userId) {
        throw new Error('Message not found or unauthorized');
      }

      // Update message status
      if (!message.isRead) {
        message.isRead = true;
        message.readAt = new Date();
        message.status = MessageStatus.READ;
        await message.save();

        // Emit read receipt through WebSocket
        this.webSocketService.sendToUser(message.senderId.toString(), 'message_read', {
          messageId: message._id,
          readAt: message.readAt
        });
      }

      return message.toObject();
    } catch (err) {
      error('Error marking message as read:', err);
      throw err;
    }
  }

  /**
   * Retrieves all message threads for a user
   * Addresses requirements: Real-time messaging system, Privacy controls
   */
  public async getUserThreads(userId: string): Promise<IMessageThread[]> {
    try {
      // Find all conversations involving the user
      const conversations = await MessageModel.aggregate([
        {
          $match: {
            $or: [{ senderId: new mongoose.Types.ObjectId(userId) }, 
                 { receiverId: new mongoose.Types.ObjectId(userId) }]
          }
        },
        {
          $group: {
            _id: {
              furnitureId: '$furnitureId',
              participants: {
                $cond: [
                  { $eq: ['$senderId', new mongoose.Types.ObjectId(userId)] },
                  ['$senderId', '$receiverId'],
                  ['$receiverId', '$senderId']
                ]
              }
            },
            lastMessage: { $last: '$$ROOT' },
            unreadCount: {
              $sum: {
                $cond: [
                  { 
                    $and: [
                      { $eq: ['$receiverId', new mongoose.Types.ObjectId(userId)] },
                      { $eq: ['$isRead', false] }
                    ]
                  },
                  1,
                  0
                ]
              }
            }
          }
        },
        { $sort: { 'lastMessage.createdAt': -1 } }
      ]);

      // Transform to thread objects
      const threads: IMessageThread[] = await Promise.all(
        conversations.map(async (conv) => ({
          id: await this.getThreadId(
            conv._id.participants[0].toString(),
            conv._id.participants[1].toString(),
            conv._id.furnitureId.toString()
          ),
          participantIds: conv._id.participants.map(p => p.toString()),
          furnitureId: conv._id.furnitureId.toString(),
          status: MessageThreadStatus.ACTIVE,
          lastMessageAt: conv.lastMessage.createdAt,
          unreadCount: conv.unreadCount,
          createdAt: conv.lastMessage.createdAt,
          updatedAt: new Date()
        }))
      );

      return threads;
    } catch (err) {
      error('Error retrieving user threads:', err);
      throw err;
    }
  }

  /**
   * Deletes a message and updates thread metadata
   * Addresses requirements: Content moderation, Privacy controls
   */
  public async deleteMessage(messageId: string, userId: string): Promise<boolean> {
    try {
      // Find and validate message
      const message = await MessageModel.findById(messageId);
      if (!message || message.senderId.toString() !== userId) {
        throw new Error('Message not found or unauthorized');
      }

      // Soft delete message
      message.status = MessageStatus.FAILED;
      message.content = '[Message deleted]';
      await message.save();

      // Emit deletion event through WebSocket
      this.webSocketService.sendToUser(message.receiverId.toString(), 'message_deleted', {
        messageId: message._id,
        threadId: await this.getThreadId(
          message.senderId.toString(),
          message.receiverId.toString(),
          message.furnitureId.toString()
        )
      });

      return true;
    } catch (err) {
      error('Error deleting message:', err);
      throw err;
    }
  }

  /**
   * Validates message content for moderation
   * Addresses requirement: Content moderation
   */
  private validateMessageContent(content: string): void {
    if (!content || content.trim().length === 0) {
      throw new Error('Message content cannot be empty');
    }
    if (content.length > 2000) {
      throw new Error('Message content exceeds maximum length');
    }
    // Add additional content moderation rules here
  }

  /**
   * Updates message thread metadata
   * Addresses requirement: Real-time messaging system
   */
  private async updateMessageThread(message: MessageDocument): Promise<void> {
    try {
      const threadId = await this.getThreadId(
        message.senderId.toString(),
        message.receiverId.toString(),
        message.furnitureId.toString()
      );

      // Emit thread update through WebSocket
      this.webSocketService.sendToUser(message.receiverId.toString(), 'thread_updated', {
        threadId,
        lastMessageAt: message.createdAt,
        unreadCount: await this.getUnreadCount(
          message.receiverId.toString(),
          message.senderId.toString(),
          message.furnitureId.toString()
        )
      });
    } catch (err) {
      error('Error updating message thread:', err);
      throw err;
    }
  }

  /**
   * Generates a consistent thread ID for a conversation
   * Addresses requirement: Real-time messaging system
   */
  private async getThreadId(userId1: string, userId2: string, furnitureId: string): Promise<string> {
    const participants = [userId1, userId2].sort();
    return `${participants[0]}_${participants[1]}_${furnitureId}`;
  }

  /**
   * Gets unread message count for a thread
   * Addresses requirement: Real-time messaging system
   */
  private async getUnreadCount(
    userId: string,
    otherUserId: string,
    furnitureId: string
  ): Promise<number> {
    return MessageModel.countDocuments({
      senderId: otherUserId,
      receiverId: userId,
      furnitureId,
      isRead: false
    });
  }

  /**
   * Validates user access to a message thread
   * Addresses requirement: Privacy controls
   */
  private async validateThreadAccess(
    userId: string,
    otherUserId: string,
    furnitureId: string
  ): Promise<void> {
    const hasAccess = await MessageModel.exists({
      $or: [
        { senderId: userId, receiverId: otherUserId, furnitureId },
        { senderId: otherUserId, receiverId: userId, furnitureId }
      ]
    });

    if (!hasAccess) {
      throw new Error('Unauthorized access to message thread');
    }
  }
}

export default MessageService;