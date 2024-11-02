//
// Furniture.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify CoreML model integration for AI metadata processing
// 2. Configure S3 bucket permissions for furniture image storage
// 3. Set up appropriate image compression and caching policies
// 4. Review pickup assistance requirements with legal team
// 5. Configure furniture listing expiration notifications

// Foundation framework - iOS 14.0+
import Foundation

// MARK: - FurnitureCategory
/// Defines categories of furniture items
/// Requirement: Furniture documentation and discovery - Core data model for furniture listing management
public enum FurnitureCategory: String, Codable {
    case seating
    case tables
    case storage
    case beds
    case lighting
    case decor
    case outdoor
    case other
}

// MARK: - FurnitureCondition
/// Defines possible conditions of furniture items
/// Requirement: Furniture documentation and discovery - Core data model for furniture listing management
public enum FurnitureCondition: String, Codable {
    case likeNew
    case good
    case fair
    case needsRepair
    case forParts
}

// MARK: - FurnitureStatus
/// Defines possible statuses of furniture listings
/// Requirement: Furniture documentation and discovery - Core data model for furniture listing management
public enum FurnitureStatus: String, Codable {
    case available
    case pending
    case claimed
    case expired
    case removed
}

// MARK: - Dimensions
/// Structure representing furniture dimensions
/// Requirement: Furniture documentation and discovery - Core data model for furniture listing management
public struct Dimensions: Codable {
    let length: Double
    let width: Double
    let height: Double
    let weight: Double?
    let unit: String
}

// MARK: - AIMetadata
/// Structure containing AI-generated metadata about the furniture
/// Requirement: AI/ML Infrastructure - Integration with AI-generated furniture metadata and classification
public struct AIMetadata: Codable {
    let style: String
    let confidenceScore: Double
    let detectedMaterials: [String]
    let suggestedCategories: [String]
    let similarItems: [String]
    let qualityAssessment: QualityAssessment
}

// MARK: - QualityAssessment
/// Structure containing AI-based quality assessment data
/// Requirement: AI/ML Infrastructure - Integration with AI-generated furniture metadata and classification
public struct QualityAssessment: Codable {
    let overallScore: Double
    let detectedIssues: [String]
    let recommendations: [String]
}

// MARK: - PickupDetails
/// Structure containing pickup arrangement details
/// Requirement: Furniture documentation and discovery - Core data model for furniture listing management
public struct PickupDetails: Codable {
    let type: String
    let availableDays: [String]
    let timeWindow: String
    let specialInstructions: String?
    let assistanceRequired: Bool
    let requiredEquipment: [String]
}

// MARK: - Furniture
/// Main furniture model class representing a furniture item in the Founditure application
/// Requirement: Furniture documentation and discovery - Core data model for furniture listing management
@objc
@objcMembers
public class Furniture: NSObject {
    // MARK: - Properties
    
    public let id: UUID
    public let userId: UUID
    public let title: String
    public let description: String
    public let category: FurnitureCategory
    public let condition: FurnitureCondition
    public let dimensions: Dimensions
    public var materials: [String]
    public var imageUrls: [String]
    public var aiMetadata: AIMetadata?
    public let location: Location
    public var status: FurnitureStatus
    public let pickupDetails: PickupDetails
    public let createdAt: Date
    public var updatedAt: Date
    public let expiresAt: Date
    
    // MARK: - Initialization
    
    /// Initializes a new furniture item
    /// Requirement: Furniture documentation and discovery - Core data model for furniture listing management
    public init(
        title: String,
        description: String,
        category: FurnitureCategory,
        condition: FurnitureCondition,
        location: Location,
        userId: UUID
    ) {
        // Generate new UUID for id
        self.id = UUID()
        
        // Set current timestamp for createdAt
        self.createdAt = Date()
        
        // Initialize with provided data
        self.title = title
        self.description = description
        self.category = category
        self.condition = condition
        self.location = location
        self.userId = userId
        
        // Set default status to available
        self.status = .available
        
        // Initialize empty arrays for materials and imageUrls
        self.materials = []
        self.imageUrls = []
        
        // Initialize default dimensions
        self.dimensions = Dimensions(
            length: 0,
            width: 0,
            height: 0,
            weight: nil,
            unit: "inches"
        )
        
        // Initialize default pickup details
        self.pickupDetails = PickupDetails(
            type: "pickup",
            availableDays: [],
            timeWindow: "9AM-5PM",
            specialInstructions: nil,
            assistanceRequired: false,
            requiredEquipment: []
        )
        
        // Set updatedAt to current time
        self.updatedAt = Date()
        
        // Calculate expiration date (30 days from creation)
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 30, to: createdAt) ?? Date()
        
        super.init()
    }
    
    // MARK: - Status Management
    
    /// Updates the furniture listing status
    /// Requirement: Furniture documentation and discovery - Core data model for furniture listing management
    public func updateStatus(_ newStatus: FurnitureStatus) {
        // Validate status transition
        guard isValidStatusTransition(from: status, to: newStatus) else {
            return
        }
        
        // Update status property
        status = newStatus
        
        // Update updatedAt timestamp
        updatedAt = Date()
        
        // Trigger status change notifications
        NotificationCenter.default.post(
            name: NSNotification.Name("FurnitureStatusChanged"),
            object: self,
            userInfo: ["status": newStatus]
        )
    }
    
    /// Updates the AI-generated metadata
    /// Requirement: AI/ML Infrastructure - Integration with AI-generated furniture metadata and classification
    public func updateAIMetadata(_ metadata: AIMetadata) {
        // Validate AI metadata
        guard metadata.confidenceScore >= 0.5 else {
            return
        }
        
        // Update aiMetadata property
        aiMetadata = metadata
        
        // Update materials if detected
        if !metadata.detectedMaterials.isEmpty {
            materials = metadata.detectedMaterials
        }
        
        // Update category if suggested with high confidence
        if metadata.confidenceScore > 0.8,
           let suggestedCategory = metadata.suggestedCategories.first,
           let newCategory = FurnitureCategory(rawValue: suggestedCategory) {
            category = newCategory
        }
        
        // Update updatedAt timestamp
        updatedAt = Date()
    }
    
    /// Updates the pickup arrangement details
    /// Requirement: Furniture documentation and discovery - Core data model for furniture listing management
    public func updatePickupDetails(_ details: PickupDetails) {
        // Validate pickup details
        guard !details.availableDays.isEmpty && !details.timeWindow.isEmpty else {
            return
        }
        
        // Update pickupDetails property
        pickupDetails = details
        
        // Update updatedAt timestamp
        updatedAt = Date()
        
        // Trigger pickup details notifications
        NotificationCenter.default.post(
            name: NSNotification.Name("FurniturePickupDetailsUpdated"),
            object: self,
            userInfo: ["pickupDetails": details]
        )
    }
    
    // MARK: - Private Helpers
    
    private func isValidStatusTransition(from currentStatus: FurnitureStatus, to newStatus: FurnitureStatus) -> Bool {
        switch (currentStatus, newStatus) {
        case (.available, .pending),
             (.available, .claimed),
             (.available, .expired),
             (.available, .removed),
             (.pending, .available),
             (.pending, .claimed),
             (.pending, .expired),
             (.pending, .removed),
             (.claimed, .removed),
             (.expired, .removed):
            return true
        default:
            return false
        }
    }
}

// MARK: - Codable Extension
extension Furniture: Codable {
    enum CodingKeys: String, CodingKey {
        case id, userId, title, description, category, condition
        case dimensions, materials, imageUrls, aiMetadata, location
        case status, pickupDetails, createdAt, updatedAt, expiresAt
    }
}

// MARK: - Identifiable Extension
extension Furniture: Identifiable {}

// MARK: - Equatable Extension
extension Furniture: Equatable {
    public static func == (lhs: Furniture, rhs: Furniture) -> Bool {
        return lhs.id == rhs.id
    }
}