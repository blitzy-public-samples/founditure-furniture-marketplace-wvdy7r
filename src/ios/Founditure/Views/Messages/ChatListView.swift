//
// ChatListView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure push notification handling for new messages
// 2. Set up message persistence encryption
// 3. Verify accessibility labels for VoiceOver support
// 4. Test chat list with different device text sizes
// 5. Configure offline message queue size limits

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// SwiftUI view that displays a list of chat conversations with real-time updates
/// Requirement: Real-time messaging - Implements chat list interface in the mobile application
struct ChatListView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = MessageViewModel(appState: AppState.shared)
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var showNewChat = false
    
    // MARK: - Computed Properties
    
    /// Filtered conversations based on search text
    private var filteredChats: [Message] {
        guard !searchText.isEmpty else { return viewModel.messages }
        return viewModel.messages.filter { message in
            message.content.localizedCaseInsensitiveContains(searchText) ||
            (message.senderName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    /// Grouped messages by conversation
    private var groupedChats: [(User, Message)] {
        let grouped = Dictionary(grouping: filteredChats) { $0.senderId }
        return grouped.compactMap { senderId, messages in
            guard let latestMessage = messages.max(by: { $0.sentAt < $1.sentAt }),
                  let user = latestMessage.sender else { return nil }
            return (user, latestMessage)
        }.sorted { $0.1.sentAt > $1.1.sentAt }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if groupedChats.isEmpty {
                    emptyStateView
                } else {
                    chatListContent
                }
            }
            .navigationTitle("Messages")
            .navigationBarItems(trailing: newChatButton)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search messages"
            )
            .refreshable {
                // Requirement: Real-time messaging - Pull-to-refresh functionality
                await refreshChats()
            }
        }
    }
    
    // MARK: - Chat List Content
    
    /// Builds the scrollable chat list content
    /// Requirement: Mobile Client Architecture - Implements chat list component
    private var chatListContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(groupedChats, id: \.1.id) { user, message in
                    chatPreviewCell(user: user, latestMessage: message)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    
                    Divider()
                        .padding(.leading, 76)
                }
            }
        }
    }
    
    /// Builds a preview cell for a chat conversation
    /// Requirement: Mobile Client Architecture - Chat preview cell component
    private func chatPreviewCell(user: User, latestMessage: Message) -> some View {
        NavigationLink(destination: ChatView(participant: user)) {
            HStack(spacing: 12) {
                // User Avatar
                AsyncImage(url: URL(string: user.profileImageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                
                // Message Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.fullName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formatTimestamp(latestMessage.sentAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(messagePreview(for: latestMessage))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Unread indicator
                        if !latestMessage.isRead && latestMessage.receiverId == AppState.shared.currentUser.id {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Supporting Views
    
    /// Loading indicator view
    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.5)
    }
    
    /// Empty state view when no chats exist
    /// Requirement: Mobile Client Architecture - Empty state handling
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Messages Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a conversation about furniture you're interested in")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: { showNewChat = true }) {
                Text("Start New Chat")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .padding(.top, 8)
        }
    }
    
    /// New chat button in navigation bar
    private var newChatButton: some View {
        Button(action: { showNewChat = true }) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 20))
        }
    }
    
    // MARK: - Helper Functions
    
    /// Formats message timestamp for display
    private func formatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
    
    /// Generates message preview text based on message type
    private func messagePreview(for message: Message) -> String {
        switch message.type {
        case .text:
            return message.content
        case .image:
            return "📷 Photo"
        case .location:
            return "📍 Location"
        case .pickupRequest:
            return "🚚 Pickup Request"
        case .statusUpdate:
            return "ℹ️ Status Update"
        default:
            return message.content
        }
    }
    
    /// Refreshes chat list
    /// Requirement: Real-time messaging - Chat list refresh functionality
    private func refreshChats() async {
        // Simulate network delay for smoother UX
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Load latest messages
        viewModel.loadMessages(conversationId: AppState.shared.currentUser.id)
    }
}

// MARK: - Preview Provider

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
            .environmentObject(AppState.shared)
    }
}