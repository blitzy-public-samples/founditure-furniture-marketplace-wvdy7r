//
// ChatBubble.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify accessibility labels are properly configured for VoiceOver support
// 2. Test chat bubble layout with different device text sizes
// 3. Ensure color contrast meets WCAG guidelines for text readability
// 4. Test RTL language support for chat bubble alignment

// SwiftUI framework - iOS 14.0+
import SwiftUI

// Internal dependencies
import "../../Models/Message"
import "../../Utils/Extensions/View+Extension"
import "../../Utils/Extensions/Color+Extension"

/// SwiftUI view that displays a single chat message bubble
/// Requirement: Real-time messaging - Provides UI component for displaying chat messages in real-time messaging system
/// Requirement: Mobile Client Architecture - Implements reusable chat bubble component for messaging interface
struct ChatBubble: View {
    // MARK: - Properties
    
    let message: Message
    let isFromCurrentUser: Bool
    let maxWidth: CGFloat
    
    // MARK: - Initialization
    
    init(message: Message, isFromCurrentUser: Bool, maxWidth: CGFloat = UIScreen.main.bounds.width * 0.7) {
        self.message = message
        self.isFromCurrentUser = isFromCurrentUser
        self.maxWidth = maxWidth
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        isFromCurrentUser ? .primary : .surface
    }
    
    private var foregroundColor: Color {
        isFromCurrentUser ? .white : .primary
    }
    
    private var alignment: HorizontalAlignment {
        isFromCurrentUser ? .trailing : .leading
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: alignment, spacing: 4) {
                messageContent
                    .foregroundColor(foregroundColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                
                statusIndicator
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }
            .background(backgroundColor)
            .roundedBorder(color: backgroundColor, lineWidth: 1)
            .cornerRadius(12)
            .frame(maxWidth: maxWidth, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    // MARK: - Message Content
    
    @ViewBuilder
    private var messageContent: some View {
        switch message.type {
        case .text:
            Text(message.content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(label: Text("Message: \(message.content)"))
            
        case .image:
            if let imageUrl = message.attachments?.first {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(8)
                } placeholder: {
                    ProgressView()
                        .frame(width: 200, height: 200)
                }
                .accessibility(label: Text("Image message"))
            }
            
        case .location:
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.title2)
                Text(message.content)
                    .font(.subheadline)
            }
            .accessibility(label: Text("Location: \(message.content)"))
            
        case .pickupRequest:
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "cube.box.fill")
                    .font(.title2)
                Text(message.content)
                    .font(.subheadline)
                if let furnitureId = message.furnitureId {
                    Text("Furniture ID: \(furnitureId.uuidString)")
                        .font(.caption)
                        .opacity(0.7)
                }
            }
            .accessibility(label: Text("Pickup request: \(message.content)"))
            
        case .statusUpdate:
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .font(.title3)
                Text(message.content)
                    .font(.subheadline)
            }
            .accessibility(label: Text("Status update: \(message.content)"))
            
        default:
            Text(message.content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .accessibility(label: Text("Message: \(message.content)"))
        }
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Text(formatTimestamp(message.sentAt))
                .font(.caption2)
                .opacity(0.7)
            
            if isFromCurrentUser {
                statusIcon
                    .font(.caption2)
                    .opacity(0.7)
            }
        }
        .foregroundColor(foregroundColor)
        .accessibility(label: Text("Sent \(formatTimestamp(message.sentAt))"))
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sent:
            Image(systemName: "checkmark")
        case .delivered:
            Image(systemName: "checkmark.circle")
        case .read:
            Image(systemName: "checkmark.circle.fill")
        case .failed:
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.error)
        case .deleted:
            Image(systemName: "trash")
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview Provider

struct ChatBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ChatBubble(
                message: Message(
                    senderId: UUID(),
                    receiverId: UUID(),
                    content: "Hello! I'm interested in the furniture you posted.",
                    type: .text
                ),
                isFromCurrentUser: true
            )
            
            ChatBubble(
                message: Message(
                    senderId: UUID(),
                    receiverId: UUID(),
                    content: "Sure! When would you like to pick it up?",
                    type: .text
                ),
                isFromCurrentUser: false
            )
            
            ChatBubble(
                message: Message(
                    senderId: UUID(),
                    receiverId: UUID(),
                    content: "123 Main Street, Apt 4B",
                    type: .location
                ),
                isFromCurrentUser: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}