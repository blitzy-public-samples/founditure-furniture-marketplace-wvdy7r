// Human Tasks:
// 1. Set up Firebase Cloud Messaging (FCM) credentials in environment variables
// 2. Configure notification templates in a separate configuration file
// 3. Set up monitoring for notification delivery rates and failures
// 4. Configure notification retry policies in environment variables
// 5. Set up notification analytics in Firebase Console

// Third-party imports with versions
import * as admin from 'firebase-admin'; // ^11.x

// Internal imports
import { IUser, IUserPreferences } from '../interfaces/user.interface';
import { logger } from '../utils/logger.utils';
import { messaging } from '../config/firebase';

/**
 * Enum defining supported notification types
 * Addresses requirement: Real-time messaging
 */
export enum NotificationType {
  FURNITURE_LISTED = 'FURNITURE_LISTED',
  MESSAGE_RECEIVED = 'MESSAGE_RECEIVED',
  POINTS_EARNED = 'POINTS_EARNED',
  LOCATION_ALERT = 'LOCATION_ALERT',
  SYSTEM_UPDATE = 'SYSTEM_UPDATE'
}

/**
 * Interface defining notification payload structure
 * Addresses requirement: Push notifications
 */
export interface NotificationPayload {
  title: string;
  body: string;
  data: Record<string, string>;
  priority: string;
  ttl: number;
}

/**
 * Service class handling all notification-related operations
 * Addresses requirements:
 * - Push notifications
 * - Real-time messaging
 * - User preferences
 */
export default class NotificationService {
  private messaging: admin.messaging.Messaging;
  private logger: typeof logger;
  private readonly DEFAULT_TTL = 24 * 60 * 60; // 24 hours in seconds
  private readonly MAX_BATCH_SIZE = 500; // FCM batch size limit
  private readonly RETRY_ATTEMPTS = 3;
  private readonly RETRY_DELAY = 1000; // 1 second

  constructor() {
    this.messaging = messaging;
    this.logger = logger;
    this.logger.info('NotificationService initialized');
  }

  /**
   * Sends a push notification to a specific user
   * Addresses requirement: Push notifications
   */
  public async sendPushNotification(
    userId: string,
    notificationData: NotificationPayload
  ): Promise<void> {
    try {
      // Validate user notification preferences
      const userPreferences = await this.validateUserPreferences(userId);
      if (!userPreferences.notifications.push) {
        this.logger.info('Push notifications disabled for user', { userId });
        return;
      }

      // Format notification payload
      const message = await this.createNotificationPayload(
        NotificationType[notificationData.data.type as keyof typeof NotificationType],
        notificationData
      );

      // Send notification through FCM
      const response = await this.messaging.send({
        token: userPreferences.fcmToken,
        ...message
      });

      this.logger.info('Push notification sent successfully', {
        userId,
        messageId: response
      });
    } catch (error) {
      await this.handleNotificationFailure(error as admin.FirebaseError, userId);
    }
  }

  /**
   * Sends notifications to multiple users
   * Addresses requirement: Real-time messaging
   */
  public async sendBulkNotifications(
    userIds: string[],
    notificationData: NotificationPayload
  ): Promise<admin.messaging.BatchResponse> {
    try {
      // Filter users by notification preferences
      const eligibleUsers = await this.filterEligibleUsers(userIds);
      
      // Batch notifications for efficient delivery
      const messages = await Promise.all(
        eligibleUsers.map(async (userId) => ({
          token: (await this.validateUserPreferences(userId)).fcmToken,
          ...await this.createNotificationPayload(
            NotificationType[notificationData.data.type as keyof typeof NotificationType],
            notificationData
          )
        }))
      );

      // Send notifications in chunks to respect FCM limits
      const chunks = this.chunkArray(messages, this.MAX_BATCH_SIZE);
      const responses = await Promise.all(
        chunks.map(chunk => this.messaging.sendAll(chunk))
      );

      // Aggregate responses
      const batchResponse = this.aggregateBatchResponses(responses);
      
      // Log batch delivery results
      this.logger.info('Bulk notifications sent', {
        totalSent: batchResponse.successCount,
        totalFailed: batchResponse.failureCount
      });

      return batchResponse;
    } catch (error) {
      this.logger.error('Bulk notification sending failed', { error });
      throw error;
    }
  }

  /**
   * Creates a formatted notification payload based on notification type
   * Addresses requirement: Push notifications
   */
  private async createNotificationPayload(
    type: NotificationType,
    data: object
  ): Promise<NotificationPayload> {
    try {
      // Select notification template
      const template = this.getNotificationTemplate(type);
      
      // Populate template with data
      const payload: NotificationPayload = {
        title: this.populateTemplate(template.title, data),
        body: this.populateTemplate(template.body, data),
        data: {
          type,
          ...this.sanitizeData(data)
        },
        priority: 'high',
        ttl: this.DEFAULT_TTL
      };

      return payload;
    } catch (error) {
      this.logger.error('Failed to create notification payload', { error, type });
      throw error;
    }
  }

  /**
   * Handles notification delivery failures and retries
   * Addresses requirement: Real-time messaging
   */
  private async handleNotificationFailure(
    error: admin.FirebaseError,
    userId: string
  ): Promise<void> {
    this.logger.error('Notification delivery failed', { error, userId });

    // Analyze error type
    switch (error.code) {
      case 'messaging/invalid-registration-token':
      case 'messaging/registration-token-not-registered':
        await this.invalidateUserToken(userId);
        break;
      
      case 'messaging/message-rate-exceeded':
        await this.handleRateLimitError(userId);
        break;
      
      case 'messaging/server-unavailable':
        await this.retryNotification(userId, error);
        break;
      
      default:
        this.logger.error('Unhandled notification error', { error });
        throw error;
    }
  }

  /**
   * Validates user notification preferences
   * Addresses requirement: User preferences
   */
  private async validateUserPreferences(userId: string): Promise<IUserPreferences & { fcmToken: string }> {
    try {
      // Fetch user preferences from database
      const preferences = await this.getUserPreferences(userId);
      
      // Validate FCM token
      if (!preferences.fcmToken) {
        throw new Error('User FCM token not found');
      }

      return preferences;
    } catch (error) {
      this.logger.error('Failed to validate user preferences', { error, userId });
      throw error;
    }
  }

  /**
   * Helper method to filter users by notification preferences
   */
  private async filterEligibleUsers(userIds: string[]): Promise<string[]> {
    const eligibleUsers = await Promise.all(
      userIds.map(async (userId) => {
        try {
          await this.validateUserPreferences(userId);
          return userId;
        } catch {
          return null;
        }
      })
    );
    return eligibleUsers.filter((id): id is string => id !== null);
  }

  /**
   * Helper method to chunk array for batch processing
   */
  private chunkArray<T>(array: T[], size: number): T[][] {
    return Array.from({ length: Math.ceil(array.length / size) }, (_, index) =>
      array.slice(index * size, (index + 1) * size)
    );
  }

  /**
   * Helper method to aggregate batch responses
   */
  private aggregateBatchResponses(
    responses: admin.messaging.BatchResponse[]
  ): admin.messaging.BatchResponse {
    return responses.reduce(
      (acc, response) => ({
        successCount: acc.successCount + response.successCount,
        failureCount: acc.failureCount + response.failureCount,
        responses: [...acc.responses, ...response.responses]
      }),
      { successCount: 0, failureCount: 0, responses: [] } as admin.messaging.BatchResponse
    );
  }

  /**
   * Helper method to get notification template
   */
  private getNotificationTemplate(type: NotificationType): { title: string; body: string } {
    const templates = {
      [NotificationType.FURNITURE_LISTED]: {
        title: 'New Furniture Listed',
        body: 'A new {furniture_type} was listed near you'
      },
      [NotificationType.MESSAGE_RECEIVED]: {
        title: 'New Message',
        body: 'You received a message from {sender_name}'
      },
      [NotificationType.POINTS_EARNED]: {
        title: 'Points Earned',
        body: 'You earned {points} points for {action}'
      },
      [NotificationType.LOCATION_ALERT]: {
        title: 'Location Alert',
        body: 'New furniture available within {distance}km'
      },
      [NotificationType.SYSTEM_UPDATE]: {
        title: 'System Update',
        body: '{message}'
      }
    };

    return templates[type];
  }

  /**
   * Helper method to populate template with data
   */
  private populateTemplate(template: string, data: object): string {
    return template.replace(
      /{(\w+)}/g,
      (match, key) => (data as any)[key] || match
    );
  }

  /**
   * Helper method to sanitize notification data
   */
  private sanitizeData(data: object): Record<string, string> {
    return Object.entries(data).reduce((acc, [key, value]) => ({
      ...acc,
      [key]: String(value)
    }), {});
  }

  /**
   * Helper method to invalidate user token
   */
  private async invalidateUserToken(userId: string): Promise<void> {
    try {
      // Update user record to remove invalid token
      // Implementation depends on your user management system
      this.logger.info('Invalidating user FCM token', { userId });
    } catch (error) {
      this.logger.error('Failed to invalidate user token', { error, userId });
    }
  }

  /**
   * Helper method to handle rate limit errors
   */
  private async handleRateLimitError(userId: string): Promise<void> {
    // Implement exponential backoff or rate limiting logic
    this.logger.warn('Rate limit exceeded for user', { userId });
  }

  /**
   * Helper method to retry failed notifications
   */
  private async retryNotification(
    userId: string,
    error: Error,
    attempt: number = 1
  ): Promise<void> {
    if (attempt > this.RETRY_ATTEMPTS) {
      this.logger.error('Max retry attempts reached', { userId, error });
      throw error;
    }

    await new Promise(resolve => setTimeout(resolve, this.RETRY_DELAY * attempt));
    // Implement retry logic here
    this.logger.info('Retrying notification', { userId, attempt });
  }

  /**
   * Helper method to get user preferences
   */
  private async getUserPreferences(userId: string): Promise<IUserPreferences & { fcmToken: string }> {
    // Implementation depends on your user management system
    // This is a placeholder that should be replaced with actual database query
    throw new Error('Method not implemented');
  }
}