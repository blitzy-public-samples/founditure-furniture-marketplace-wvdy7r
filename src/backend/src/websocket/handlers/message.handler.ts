/**
 * Human Tasks:
 * 1. Configure WebSocket event rate limiting in production
 * 2. Set up monitoring for message delivery latency
 * 3. Configure content moderation rules and thresholds
 * 4. Set up alerts for failed message deliveries
 * 5. Configure message retention policies
 */

// Third-party imports with versions
import { Socket } from 'socket.io'; // ^4.7.0

// Internal imports
import MessageService from '../../services/message.service';
import WebSocketService from '../../services/websocket.service';
import { 
  IMessage, 
  MessageType, 
  MessageStatus, 
  IMessageThread 
} from '../../interfaces/message.interface';
import { error } from '../../utils/logger.utils';

/**
 * WebSocket handler for real-time messaging functionality
 * Addresses requirements:
 * - Real-time messaging system (1.2 Scope/Core System Components)
 * - Content moderation (1.2 Scope/Included Features)
 * - Privacy controls (1.2 Scope/Included Features)
 */
class MessageHandler {
  private messageService: MessageService;
  private webSocketService: WebSocketService;

  constructor(messageService: MessageService, webSocketService: WebSocketService) {
    this.messageService = messageService;
    this.webSocketService = webSocketService;
  }

  /**
   * Handles private messages between users
   * Addresses requirements: Real-time messaging system, Content moderation
   */
  public async handlePrivateMessage(socket: Socket, messageData: IMessage): Promise<void> {
    try {
      // Validate user authorization
      const senderId = socket.data.userId;
      if (senderId !== messageData.senderId) {
        throw new Error('Unauthorized message sender');
      }

      // Process and save message
      const savedMessage = await this.messageService.sendMessage({
        ...messageData,
        type: MessageType.TEXT,
        status: MessageStatus.SENT,
        isRead: false,
        createdAt: new Date(),
        updatedAt: new Date()
      });

      // Emit message to recipient
      this.webSocketService.sendToUser(messageData.receiverId, 'new_message', {
        message: savedMessage,
        threadId: await this.messageService.getThreadId(
          savedMessage.senderId,
          savedMessage.receiverId,
          savedMessage.furnitureId
        )
      });

      // Send delivery status to sender
      socket.emit('message_sent', {
        messageId: savedMessage.id,
        status: MessageStatus.DELIVERED,
        timestamp: new Date()
      });

    } catch (err) {
      error('Error handling private message:', err);
      socket.emit('message_error', {
        error: 'Failed to send message',
        timestamp: new Date()
      });
    }
  }

  /**
   * Manages typing indicators for message threads
   * Addresses requirement: Real-time messaging system
   */
  public handleTypingStatus(socket: Socket, data: { threadId: string, isTyping: boolean }): void {
    try {
      const userId = socket.data.userId;
      
      // Get thread participants
      const [participant1, participant2] = data.threadId.split('_');
      const recipientId = participant1 === userId ? participant2 : participant1;

      // Emit typing status to recipient
      this.webSocketService.sendToUser(recipientId, 'typing_status', {
        threadId: data.threadId,
        userId: userId,
        isTyping: data.isTyping,
        timestamp: new Date()
      });

      // Clear typing status after timeout if active
      if (data.isTyping) {
        setTimeout(() => {
          this.webSocketService.sendToUser(recipientId, 'typing_status', {
            threadId: data.threadId,
            userId: userId,
            isTyping: false,
            timestamp: new Date()
          });
        }, 5000); // 5 second timeout
      }

    } catch (err) {
      error('Error handling typing status:', err);
      socket.emit('status_error', {
        error: 'Failed to update typing status',
        timestamp: new Date()
      });
    }
  }

  /**
   * Processes message read receipts
   * Addresses requirement: Real-time messaging system
   */
  public async handleReadReceipt(socket: Socket, data: { messageId: string }): Promise<void> {
    try {
      const userId = socket.data.userId;

      // Update message read status
      const updatedMessage = await this.messageService.markMessageAsRead(
        data.messageId,
        userId
      );

      // Notify message sender
      this.webSocketService.sendToUser(updatedMessage.senderId, 'message_read', {
        messageId: updatedMessage.id,
        threadId: await this.messageService.getThreadId(
          updatedMessage.senderId,
          updatedMessage.receiverId,
          updatedMessage.furnitureId
        ),
        readAt: updatedMessage.readAt,
        timestamp: new Date()
      });

      // Update thread metadata
      const thread = await this.messageService.getMessageThread(
        updatedMessage.senderId,
        updatedMessage.receiverId,
        updatedMessage.furnitureId
      );

      // Emit thread update
      this.webSocketService.sendToUser(userId, 'thread_updated', {
        threadId: thread.id,
        unreadCount: thread.unreadCount,
        timestamp: new Date()
      });

    } catch (err) {
      error('Error handling read receipt:', err);
      socket.emit('receipt_error', {
        error: 'Failed to process read receipt',
        timestamp: new Date()
      });
    }
  }

  /**
   * Handles message deletion requests
   * Addresses requirements: Content moderation, Privacy controls
   */
  public async handleMessageDelete(socket: Socket, data: { messageId: string }): Promise<void> {
    try {
      const userId = socket.data.userId;

      // Delete message and get thread participants
      const deletedMessage = await this.messageService.deleteMessage(
        data.messageId,
        userId
      );

      if (deletedMessage) {
        // Notify thread participants
        const threadId = await this.messageService.getThreadId(
          deletedMessage.senderId,
          deletedMessage.receiverId,
          deletedMessage.furnitureId
        );

        // Notify recipient
        this.webSocketService.sendToUser(deletedMessage.receiverId, 'message_deleted', {
          messageId: data.messageId,
          threadId: threadId,
          timestamp: new Date()
        });

        // Confirm deletion to sender
        socket.emit('delete_confirmed', {
          messageId: data.messageId,
          threadId: threadId,
          timestamp: new Date()
        });

        // Update thread metadata for both participants
        const thread = await this.messageService.getMessageThread(
          deletedMessage.senderId,
          deletedMessage.receiverId,
          deletedMessage.furnitureId
        );

        [deletedMessage.senderId, deletedMessage.receiverId].forEach(participantId => {
          this.webSocketService.sendToUser(participantId, 'thread_updated', {
            threadId: thread.id,
            lastMessageAt: thread.lastMessageAt,
            timestamp: new Date()
          });
        });
      }

    } catch (err) {
      error('Error handling message deletion:', err);
      socket.emit('delete_error', {
        error: 'Failed to delete message',
        timestamp: new Date()
      });
    }
  }
}

export default MessageHandler;