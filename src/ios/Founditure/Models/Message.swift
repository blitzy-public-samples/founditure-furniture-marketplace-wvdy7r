//
// Message.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure WebSocket integration for real-time message delivery
// 2. Set up push notification certificates for message notifications
// 3. Verify message encryption implementation
// 4. Configure message retention policies
// 5. Set up message delivery status tracking

// Foundation framework - iOS 14.0+
import Foundation

// Internal dependencies
import User
import Furniture

// MARK: - MessageType
/// Defines types of messages in the system
/// Requirement: Real-time messaging - Core data model for user-to-user messaging system
public enum MessageType: String, Codable {
    case text
    case image
    case location
    case pickupRequest
    case pickupConfirmation
    case statusUpdate
    case system
}

// MARK: - MessageStatus
/// Defines possible statuses of messages
/// Requirement: Real-time messaging - Core data model for user-to-user messaging system
public enum MessageStatus: String, Codable {
    case sent
    case delivered
    case read
    case failed
    case deleted
}

// MARK: - Message
/// Main message model class representing a message in the Founditure application
/// Requirement: Real-time messaging - Core data model for user-to-user messaging system
@objc
@objcMembers
public class Message: NSObject {
    // MARK: - Properties
    
    public let id: UUID
    public let senderId: UUID
    public let receiverId: UUID
    public let furnitureId: UUID?
    public let content: String
    public let type: MessageType
    public private(set) var status: MessageStatus
    public private(set) var isRead: Bool
    public let sentAt: Date
    public private(set) var deliveredAt: Date?
    public private(set) var readAt: Date?
    public private(set) var attachments: [String]?
    public private(set) var metadata: [String: Any]?
    
    // MARK: - Initialization
    
    /// Initializes a new message instance
    /// Requirement: Real-time messaging - Core data model for user-to-user messaging system
    public init(
        senderId: UUID,
        receiverId: UUID,
        content: String,
        type: MessageType,
        furnitureId: UUID? = nil
    ) {
        // Generate new UUID for id
        self.id = UUID()
        
        // Set current timestamp for sentAt
        self.sentAt = Date()
        
        // Initialize message with provided data
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.type = type
        self.furnitureId = furnitureId
        
        // Set initial status to sent
        self.status = .sent
        
        // Set isRead to false
        self.isRead = false
        
        // Initialize empty arrays for attachments if needed
        self.attachments = type == .image ? [] : nil
        
        // Set metadata based on message type
        self.metadata = Message.generateMetadata(for: type, furnitureId: furnitureId)
        
        super.init()
    }
    
    // MARK: - Status Management
    
    /// Marks the message as delivered
    /// Requirement: Real-time messaging - Core data model for user-to-user messaging system
    public func markAsDelivered() {
        // Update status to delivered
        status = .delivered
        
        // Set current timestamp for deliveredAt
        deliveredAt = Date()
        
        // Trigger delivery notifications
        NotificationCenter.default.post(
            name: NSNotification.Name("MessageDelivered"),
            object: self,
            userInfo: ["messageId": id]
        )
    }
    
    /// Marks the message as read
    /// Requirement: Real-time messaging - Core data model for user-to-user messaging system
    public func markAsRead() {
        // Update status to read
        status = .read
        
        // Set isRead to true
        isRead = true
        
        // Set current timestamp for readAt
        readAt = Date()
        
        // Trigger read receipt notifications
        NotificationCenter.default.post(
            name: NSNotification.Name("MessageRead"),
            object: self,
            userInfo: ["messageId": id]
        )
    }
    
    /// Adds an attachment to the message
    /// Requirement: Real-time messaging - Core data model for user-to-user messaging system
    public func addAttachment(_ attachmentUrl: String) -> Bool {
        // Validate attachment URL
        guard URL(string: attachmentUrl) != nil else {
            return false
        }
        
        // Add URL to attachments array
        if attachments == nil {
            attachments = []
        }
        attachments?.append(attachmentUrl)
        
        // Update metadata if needed
        if var meta = metadata {
            meta["hasAttachments"] = true
            meta["attachmentCount"] = attachments?.count ?? 0
            metadata = meta
        }
        
        return true
    }
    
    // MARK: - Private Helpers
    
    private static func generateMetadata(for type: MessageType, furnitureId: UUID?) -> [String: Any] {
        var metadata: [String: Any] = [
            "messageType": type.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        switch type {
        case .image:
            metadata["hasAttachments"] = true
            metadata["attachmentCount"] = 0
            
        case .location:
            metadata["requiresLocationAccess"] = true
            
        case .pickupRequest, .pickupConfirmation:
            if let furnitureId = furnitureId {
                metadata["furnitureId"] = furnitureId.uuidString
                metadata["requiresResponse"] = true
            }
            
        case .statusUpdate:
            metadata["isSystemGenerated"] = true
            if let furnitureId = furnitureId {
                metadata["furnitureId"] = furnitureId.uuidString
            }
            
        case .system:
            metadata["isSystemGenerated"] = true
            metadata["priority"] = "normal"
            
        default:
            break
        }
        
        return metadata
    }
}

// MARK: - Codable Extension
extension Message: Codable {
    enum CodingKeys: String, CodingKey {
        case id, senderId, receiverId, furnitureId, content, type
        case status, isRead, sentAt, deliveredAt, readAt
        case attachments, metadata
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(furnitureId, forKey: .furnitureId)
        try container.encode(content, forKey: .content)
        try container.encode(type, forKey: .type)
        try container.encode(status, forKey: .status)
        try container.encode(isRead, forKey: .isRead)
        try container.encode(sentAt, forKey: .sentAt)
        try container.encode(deliveredAt, forKey: .deliveredAt)
        try container.encode(readAt, forKey: .readAt)
        try container.encode(attachments, forKey: .attachments)
        try container.encode(metadata as? [String: String], forKey: .metadata)
    }
}

// MARK: - Identifiable Extension
extension Message: Identifiable {}

// MARK: - Equatable Extension
extension Message: Equatable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
}