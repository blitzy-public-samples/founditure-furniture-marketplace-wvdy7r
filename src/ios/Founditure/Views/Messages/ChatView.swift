//
// ChatView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure push notification handling for new messages
// 2. Set up message persistence encryption keys
// 3. Configure offline message queue size limits
// 4. Verify WebSocket SSL certificates
// 5. Set up message retention policies

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// SwiftUI view that implements a real-time chat interface
/// Requirement: Real-time messaging - Implements real-time messaging interface with WebSocket integration
struct ChatView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: MessageViewModel
    @State private var messageText: String = ""
    @State private var isShowingImagePicker: Bool = false
    @State private var isShowingLocationPicker: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showingError: Bool = false
    @State private var isScrollToBottom: Bool = false
    
    private let conversationId: UUID
    private let receiverId: UUID
    private let furnitureId: UUID?
    
    // MARK: - Initialization
    
    init(conversationId: UUID, receiverId: UUID, furnitureId: UUID? = nil) {
        self.conversationId = conversationId
        self.receiverId = receiverId
        self.furnitureId = furnitureId
        
        // Initialize view model
        let appState = AppState.shared
        _viewModel = StateObject(wrappedValue: MessageViewModel(appState: appState))
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Message list
            messageList()
                .padding(.bottom, 8)
            
            // Input toolbar
            inputToolbar()
                .background(Color(.systemBackground))
                .shadow(radius: 2)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadMessages(conversationId: conversationId)
        }
        .onChange(of: viewModel.messages) { _ in
            if isScrollToBottom {
                scrollToBottom()
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.error?.localizedDescription ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedImage: $selectedImage) { image in
                handleImageSelection(image)
            }
        }
        .sheet(isPresented: $isShowingLocationPicker) {
            LocationPicker { location in
                handleLocationSelection(location)
            }
        }
    }
    
    // MARK: - Message List
    
    /// Creates the scrolling list of messages
    /// Requirement: Mobile Client Architecture - Implements chat interface following mobile client architecture patterns
    private func messageList() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(groupedMessages, id: \.date) { group in
                        Section(header: dateHeader(for: group.date)) {
                            ForEach(group.messages) { message in
                                ChatBubble(
                                    message: message,
                                    isFromCurrentUser: message.senderId == AppState.shared.currentUser.id
                                )
                                .id(message.id)
                                .onAppear {
                                    if !message.isRead && message.senderId != AppState.shared.currentUser.id {
                                        viewModel.markAsRead([message.id])
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .onAppear {
                scrollToBottom(proxy: proxy)
            }
        }
    }
    
    /// Creates a date header for message groups
    private func dateHeader(for date: Date) -> some View {
        Text(formatDate(date))
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
    }
    
    // MARK: - Input Toolbar
    
    /// Creates the message input toolbar
    /// Requirement: Real-time messaging - Implements message composition interface
    private func inputToolbar() -> some View {
        HStack(spacing: 12) {
            // Attachment button
            Button(action: showAttachmentOptions) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            
            // Text input field
            TextField("Type a message...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.send)
                .onSubmit {
                    sendTextMessage()
                }
            
            // Send button
            Button(action: sendTextMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(messageText.isEmpty ? .secondary : .accentColor)
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Actions
    
    /// Sends a text message
    /// Requirement: Real-time messaging - Implements message sending functionality
    private func sendTextMessage() {
        guard !messageText.isEmpty else { return }
        
        let content = messageText
        messageText = ""
        isScrollToBottom = true
        
        viewModel.sendMessage(
            content: content,
            receiverId: receiverId,
            furnitureId: furnitureId,
            type: .text
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure = completion {
                    showingError = true
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &viewModel.cancellables)
    }
    
    /// Shows attachment options menu
    private func showAttachmentOptions() {
        let alert = UIAlertController(
            title: nil,
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Photo", style: .default) { _ in
            isShowingImagePicker = true
        })
        
        alert.addAction(UIAlertAction(title: "Location", style: .default) { _ in
            isShowingLocationPicker = true
        })
        
        if let furnitureId = furnitureId {
            alert.addAction(UIAlertAction(title: "Pickup Request", style: .default) { _ in
                sendPickupRequest(furnitureId: furnitureId)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
    
    /// Handles image selection from picker
    /// Requirement: Real-time messaging - Implements image sharing
    private func handleImageSelection(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            showingError = true
            return
        }
        
        // Upload image and send message
        // Implementation depends on storage service
        isScrollToBottom = true
    }
    
    /// Handles location selection from picker
    /// Requirement: Real-time messaging - Implements location sharing
    private func handleLocationSelection(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                viewModel.error = error
                showingError = true
                return
            }
            
            guard let placemark = placemarks?.first else { return }
            
            let address = [
                placemark.thoroughfare,
                placemark.locality,
                placemark.administrativeArea,
                placemark.postalCode
            ]
            .compactMap { $0 }
            .joined(separator: ", ")
            
            isScrollToBottom = true
            
            viewModel.sendMessage(
                content: address,
                receiverId: receiverId,
                furnitureId: furnitureId,
                type: .location
            )
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        showingError = true
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &viewModel.cancellables)
        }
    }
    
    /// Sends a pickup request message
    /// Requirement: Real-time messaging - Implements pickup requests
    private func sendPickupRequest(furnitureId: UUID) {
        isScrollToBottom = true
        
        viewModel.sendMessage(
            content: "I would like to pick up this item. Is it still available?",
            receiverId: receiverId,
            furnitureId: furnitureId,
            type: .pickupRequest
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure = completion {
                    showingError = true
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &viewModel.cancellables)
    }
    
    // MARK: - Helper Functions
    
    /// Groups messages by date
    private var groupedMessages: [(date: Date, messages: [Message])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.messages) { message in
            calendar.startOfDay(for: message.sentAt)
        }
        return grouped.map { (date: $0.key, messages: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    /// Formats date for headers
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    /// Scrolls to bottom of chat
    private func scrollToBottom(proxy: ScrollViewProxy? = nil) {
        if let lastMessage = viewModel.messages.last {
            withAnimation {
                proxy?.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
        isScrollToBottom = false
    }
}

// MARK: - Preview Provider

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView(
                conversationId: UUID(),
                receiverId: UUID(),
                furnitureId: UUID()
            )
        }
    }
}