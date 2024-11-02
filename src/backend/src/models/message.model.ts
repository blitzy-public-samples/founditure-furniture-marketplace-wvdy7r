// @package mongoose ^7.x
import { Schema, model, Document, Model, Types } from 'mongoose';
import { IMessage, MessageType, MessageStatus } from '../interfaces/message.interface';

/**
 * Human tasks:
 * 1. Ensure MongoDB indexes are created for optimal query performance
 * 2. Configure MongoDB TTL index for message cleanup if required
 * 3. Set up appropriate MongoDB user permissions for message operations
 */

/**
 * Interface extending IMessage for Mongoose document methods
 * Addresses requirement: Real-time messaging system - Core data structure definitions
 */
export interface MessageDocument extends IMessage, Document {
  markAsRead(): Promise<void>;
}

/**
 * Mongoose schema for messages
 * Addresses requirements:
 * - Real-time messaging system - Core messaging functionality
 * - Content moderation - Message content validation
 * - Privacy controls - Message privacy settings
 */
const messageSchema = new Schema<MessageDocument>({
  senderId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  receiverId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  furnitureId: {
    type: Schema.Types.ObjectId,
    ref: 'Furniture',
    required: true,
    index: true
  },
  content: {
    type: String,
    required: true,
    trim: true,
    maxlength: 2000, // Content moderation: Limit message length
    validate: {
      validator: function(v: string) {
        // Content moderation: Basic content validation
        return v.length > 0 && !(/^\s*$/.test(v));
      },
      message: 'Message content cannot be empty or contain only whitespace'
    }
  },
  type: {
    type: String,
    enum: Object.values(MessageType),
    default: MessageType.TEXT,
    required: true
  },
  status: {
    type: String,
    enum: Object.values(MessageStatus),
    default: MessageStatus.SENT,
    required: true
  },
  isRead: {
    type: Boolean,
    default: false,
    required: true,
    index: true
  },
  readAt: {
    type: Date,
    default: null
  },
  createdAt: {
    type: Date,
    default: Date.now,
    required: true,
    index: true
  },
  updatedAt: {
    type: Date,
    default: Date.now,
    required: true
  }
}, {
  timestamps: true, // Automatically manage createdAt and updatedAt
  collection: 'messages',
  versionKey: false
});

/**
 * Pre-save middleware to handle message timestamps
 * Addresses requirement: Real-time messaging system - Message state management
 */
messageSchema.pre('save', async function(next) {
  if (this.isModified()) {
    this.updatedAt = new Date();
  }
  
  if (this.isNew) {
    this.createdAt = new Date();
    if (!this.status) {
      this.status = MessageStatus.SENT;
    }
    if (this.isRead === undefined) {
      this.isRead = false;
    }
  }
  
  next();
});

/**
 * Method to mark a message as read
 * Addresses requirement: Real-time messaging system - Message state management
 */
messageSchema.methods.markAsRead = async function(): Promise<void> {
  if (!this.isRead) {
    this.isRead = true;
    this.readAt = new Date();
    this.status = MessageStatus.READ;
    await this.save();
  }
};

/**
 * Compound indexes for efficient querying
 * Addresses requirement: Real-time messaging system - Performance optimization
 */
messageSchema.index({ senderId: 1, receiverId: 1, createdAt: -1 });
messageSchema.index({ furnitureId: 1, createdAt: -1 });
messageSchema.index({ status: 1, createdAt: -1 });

/**
 * Message model for MongoDB operations
 * Addresses requirement: Real-time messaging system - Data persistence
 */
const MessageModel: Model<MessageDocument> = model<MessageDocument>('Message', messageSchema);

export default MessageModel;