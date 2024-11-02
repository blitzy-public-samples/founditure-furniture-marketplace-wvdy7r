// @package typescript ^5.0.0
import { IUser } from './user.interface';
import { IFurniture } from './furniture.interface';

/**
 * Enumeration of message types
 * Addresses requirement: Real-time messaging system - Core data structure definitions
 */
export enum MessageType {
  TEXT = 'TEXT',
  IMAGE = 'IMAGE',
  SYSTEM = 'SYSTEM',
  LOCATION = 'LOCATION',
  ARRANGEMENT = 'ARRANGEMENT'
}

/**
 * Enumeration of message delivery statuses
 * Addresses requirement: Real-time messaging system - Core data structure definitions
 */
export enum MessageStatus {
  SENT = 'SENT',
  DELIVERED = 'DELIVERED',
  READ = 'READ',
  FAILED = 'FAILED'
}

/**
 * Enumeration of message thread statuses
 * Addresses requirement: Real-time messaging system - Core data structure definitions
 * Addresses requirement: Privacy controls - Message privacy and visibility settings
 */
export enum MessageThreadStatus {
  ACTIVE = 'ACTIVE',
  ARCHIVED = 'ARCHIVED',
  BLOCKED = 'BLOCKED',
  DELETED = 'DELETED'
}

/**
 * Enumeration of message attachment types
 * Addresses requirement: Real-time messaging system - Core data structure definitions
 */
export enum AttachmentType {
  IMAGE = 'IMAGE',
  LOCATION = 'LOCATION',
  DOCUMENT = 'DOCUMENT'
}

/**
 * Interface defining a message in the system
 * Addresses requirement: Real-time messaging system - Core data structure definitions
 */
export interface IMessage {
  id: string;
  senderId: string;
  receiverId: string;
  furnitureId: string;
  content: string;
  type: MessageType;
  status: MessageStatus;
  isRead: boolean;
  readAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Interface defining message thread metadata
 * Addresses requirements:
 * - Real-time messaging system - Core data structure definitions
 * - Privacy controls - Message privacy and visibility settings
 */
export interface IMessageThread {
  id: string;
  participantIds: string[];
  furnitureId: string;
  status: MessageThreadStatus;
  lastMessageAt: Date;
  unreadCount: number;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Interface defining message attachments
 * Addresses requirement: Real-time messaging system - Core data structure definitions
 */
export interface IMessageAttachment {
  id: string;
  messageId: string;
  type: AttachmentType;
  url: string;
  mimeType: string;
  size: number;
  filename: string;
}