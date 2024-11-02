//
// MessagesView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure push notification permissions for message alerts
// 2. Set up keyboard appearance customization
// 3. Verify VoiceOver accessibility for message interactions
// 4. Test message input with different keyboard types
// 5. Configure message attachment size limits

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// Main view for displaying chat conversations and handling messaging functionality
/// Requirement: Real-time messaging - Implements real-time messaging system with chat interface
/// Requirement: Mobile Client Architecture - Implements main messaging interface in the mobile client
struct MessagesView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = MessageViewModel(appState: AppState())
    @State private var messageText = ""
    @State private var isShowingImagePicker = false
    @State private var isShowingLocationPicker = false
    @State private var keyboardHeight: CGFloat = 0
    
    // Constants
    private let maxMessageLength = 1000
    private let inputBarHeight: CGFloat = 60
    private let attachmentButtonSize: CGFloat = 44
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            chatHeader
                .padding(.horizontal)
                .padding(.top, 8)
            
            // Message list
            messageList
            
            // Message input bar
            messageInputBar
                .padding(.bottom, keyboardHeight)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(onImageSelected: handleImageSelected)
        }
        .sheet(isPresented: $isShowingLocationPicker) {
            LocationPicker(onLocationSelected: handleLocationSelected)
        }
        .onAppear {
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
    }
    
    // MARK: - Chat Header
    
    private var chatHeader: some View {
        HStack {
            Text("Messages")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Button(action: { /* Implement settings action */ }) {
                Image(systemName: "gear")
                    .font(.title3)
            }
        }
        .padding(.bottom, 8)
        .accessibility(label: Text("Messages screen"))
    }
    
    // MARK: - Message List
    
    /// Scrollable list of messages
    /// Requirement: Real-time messaging - Displays chat messages in real-time
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    ForEach(viewModel.messages) { message in
                        ChatBubble(
                            message: message,
                            isFromCurrentUser: message.senderId == AppState().currentUser.id
                        )
                        .id(message.id)
                        .transition(.opacity)
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: viewModel.messages) { messages in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
        .accessibility(label: Text("Message list"))
    }
    
    // MARK: - Message Input Bar
    
    /// Message input bar with attachments
    /// Requirement: Real-time messaging - Provides message composition interface
    private var messageInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Attachment button
                Button(action: showAttachmentOptions) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .frame(width: attachmentButtonSize, height: attachmentButtonSize)
                }
                .accessibility(label: Text("Add attachment"))
                
                // Text input field
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(height: 36)
                    .disabled(viewModel.isLoading)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .opacity(messageText.isEmpty ? 0.5 : 1.0)
                }
                .disabled(messageText.isEmpty || viewModel.isLoading)
                .accessibility(label: Text("Send message"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(height: inputBarHeight)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Actions
    
    /// Sends a new message
    /// Requirement: Real-time messaging - Handles message sending
    /// Requirement: Offline-first architecture - Supports offline message composition
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Send message through view model
        viewModel.sendMessage(
            content: trimmedMessage,
            receiverId: UUID(), // Replace with actual recipient ID
            type: .text
        )
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    // Handle error
                    print("Error sending message: \(error)")
                }
            },
            receiveValue: { _ in
                // Clear input field on success
                messageText = ""
            }
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
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present alert
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }
    
    /// Handles selected image from picker
    /// Requirement: Real-time messaging - Supports image attachments
    private func handleImageSelected(_ image: UIImage) {
        // Process and send image message
        viewModel.sendMessage(
            content: "Image",
            receiverId: UUID(), // Replace with actual recipient ID
            type: .image
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in }
        )
        .store(in: &viewModel.cancellables)
    }
    
    /// Handles selected location from picker
    /// Requirement: Real-time messaging - Supports location sharing
    private func handleLocationSelected(_ location: CLLocation) {
        // Process and send location message
        viewModel.sendMessage(
            content: "\(location.coordinate.latitude),\(location.coordinate.longitude)",
            receiverId: UUID(), // Replace with actual recipient ID
            type: .location
        )
        .sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in }
        )
        .store(in: &viewModel.cancellables)
    }
}

// MARK: - Keyboard Handling Extension

extension MessagesView: KeyboardReadable {
    /// Sets up keyboard observers
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            keyboardHeight = keyboardFrame?.height ?? 0
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
    
    /// Removes keyboard observers
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
}

// MARK: - Preview Provider

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}