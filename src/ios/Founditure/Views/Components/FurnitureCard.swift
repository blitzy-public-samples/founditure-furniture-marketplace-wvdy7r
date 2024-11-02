//
// FurnitureCard.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify image caching policy is configured in Xcode project settings
// 2. Test accessibility labels with VoiceOver enabled
// 3. Ensure proper image compression settings for AsyncImage loading
// 4. Verify color contrast ratios meet WCAG guidelines

// SwiftUI framework - iOS 14.0+
import SwiftUI

// Internal dependencies
import "../../Models/Furniture"
import "../../Utils/Extensions/View+Extension"
import "../../Utils/Constants/AppConstants"

/// A SwiftUI view that displays a furniture item in a card format
/// Requirement: Mobile Applications - Implements native iOS UI component using SwiftUI for furniture item display
/// Requirement: Furniture documentation and discovery - Provides visual representation of furniture listings with essential details
struct FurnitureCard: View {
    // MARK: - Properties
    
    private let furniture: Furniture
    private let isInteractive: Bool
    private let onTap: ((Furniture) -> Void)?
    private let onSave: ((Furniture) -> Void)?
    
    @State private var isImageLoading: Bool = true
    @State private var imageLoadError: Bool = false
    
    // MARK: - Initialization
    
    /// Initializes a new furniture card view
    /// - Parameters:
    ///   - furniture: The furniture item to display
    ///   - isInteractive: Flag indicating if the card should respond to user interactions
    ///   - onTap: Optional closure to handle tap gestures
    ///   - onSave: Optional closure to handle save actions
    init(
        furniture: Furniture,
        isInteractive: Bool = true,
        onTap: ((Furniture) -> Void)? = nil,
        onSave: ((Furniture) -> Void)? = nil
    ) {
        self.furniture = furniture
        self.isInteractive = isInteractive
        self.onTap = onTap
        self.onSave = onSave
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Furniture image section
            furnitureImage()
            
            // Details section
            detailsSection()
            
            // Interactive elements
            if isInteractive {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        onSave?(furniture)
                    }) {
                        Image(systemName: "bookmark")
                            .foregroundColor(.primary)
                            .padding(8)
                    }
                    .accessibility(label: Text("Save furniture item"))
                }
            }
        }
        .cardStyle()
        .roundedBorder(color: .gray.opacity(0.2), lineWidth: 1)
        .onTapGesture {
            if isInteractive {
                onTap?(furniture)
            }
        }
        .animation(.easeInOut(duration: DEFAULT_ANIMATION_DURATION))
    }
    
    // MARK: - Private Views
    
    /// Creates the furniture image view
    /// - Returns: Configured image view
    private func furnitureImage() -> some View {
        Group {
            if let imageUrl = furniture.imageUrls.first {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .foregroundColor(.gray)
            }
        }
        .cornerRadius(8)
    }
    
    /// Creates the furniture details section
    /// - Returns: Details view with title and metadata
    private func detailsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(furniture.title)
                .font(.headline)
                .lineLimit(2)
                .accessibility(label: Text("Furniture title: \(furniture.title)"))
            
            // Category and condition
            HStack {
                Text(furniture.category.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(furniture.condition.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .accessibility(label: Text("Category: \(furniture.category.rawValue), Condition: \(furniture.condition.rawValue)"))
            
            // Location information
            // Requirement: Location-based search - Displays distance information for furniture items
            if let distance = furniture.location.distance {
                Text("\(String(format: "%.1f", distance)) km away")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibility(label: Text("\(String(format: "%.1f", distance)) kilometers away"))
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Preview Provider

#if DEBUG
struct FurnitureCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFurniture = Furniture(
            title: "Vintage Wooden Chair",
            description: "Beautiful vintage chair in excellent condition",
            category: .seating,
            condition: .good,
            location: Location(latitude: 0, longitude: 0),
            userId: UUID()
        )
        
        Group {
            FurnitureCard(furniture: sampleFurniture)
                .previewLayout(.sizeThatFits)
                .padding()
            
            FurnitureCard(furniture: sampleFurniture, isInteractive: false)
                .previewLayout(.sizeThatFits)
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}
#endif