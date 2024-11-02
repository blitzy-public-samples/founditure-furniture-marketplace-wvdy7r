//
// ProfileEditView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure proper analytics tracking for profile edits
// 2. Set up proper error tracking integration
// 3. Verify accessibility labels are properly configured
// 4. Review privacy policy compliance for data collection
// 5. Configure proper keyboard handling for text fields

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// SwiftUI view for editing user profile information
/// Requirement: User registration and authentication - Provides interface for users to edit their profile information
struct ProfileEditView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: ProfileViewModel
    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var showImagePicker: Bool = false
    @State private var profileImage: UIImage?
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Privacy Settings
    @State private var isLocationVisible: Bool = true
    @State private var isProfilePublic: Bool = true
    @State private var allowMessages: Bool = true
    
    // MARK: - Initialization
    
    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Profile Image Section
                Section(header: Text("Profile Photo")) {
                    HStack {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: { showImagePicker = true }) {
                            Text("Change Photo")
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Personal Information Section
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                        .disableAutocorrection(true)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                // Privacy Settings Section
                // Requirement: Privacy controls - Allows users to manage their privacy settings and preferences
                Section(header: Text("Privacy Settings")) {
                    Toggle("Public Profile", isOn: $isProfilePublic)
                    Toggle("Show Location", isOn: $isLocationVisible)
                    Toggle("Allow Messages", isOn: $allowMessages)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveChanges()
                }
                .disabled(isLoading)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Profile Update"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if !alertMessage.contains("Error") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage)
            }
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.2))
                    }
                }
            )
        }
        .onAppear(perform: loadCurrentUserData)
    }
    
    // MARK: - Private Methods
    
    /// Loads current user data into the form
    private func loadCurrentUserData() {
        if let user = viewModel.user {
            fullName = user.fullName
            phoneNumber = user.phoneNumber ?? ""
            
            // Load privacy settings
            let privacySettings = user.privacySettings
            isProfilePublic = privacySettings.isProfilePublic
            isLocationVisible = privacySettings.isLocationVisible
            allowMessages = privacySettings.allowMessages
        }
    }
    
    /// Saves profile changes
    /// Requirement: User registration and authentication - Handles profile data updates
    private func saveChanges() {
        isLoading = true
        
        // Validate input data
        let validationResult = ValidationHelper.validateUserCredentials(
            email: viewModel.user?.email ?? "",
            password: "" // Not updating password here
        )
        
        guard case .success = validationResult else {
            alertMessage = "Please check your input data"
            showAlert = true
            isLoading = false
            return
        }
        
        // Process profile image if changed
        Task {
            var imageData: Data?
            if let image = profileImage {
                let imageProcessor = ImageProcessor()
                imageData = imageProcessor.optimizeForUpload(image)
            }
            
            // Update privacy settings
            let privacySettings = PrivacySettings(
                isProfilePublic: isProfilePublic,
                isLocationVisible: isLocationVisible,
                allowMessages: allowMessages
            )
            
            // Update profile
            do {
                try await viewModel.updateProfile(
                    fullName: fullName,
                    phoneNumber: phoneNumber,
                    profileImageUrl: nil // Will be set after upload
                )
                .flatMap { _ in
                    viewModel.updatePrivacySettings(settings: privacySettings)
                }
                .sink(
                    receiveCompletion: { completion in
                        isLoading = false
                        switch completion {
                        case .finished:
                            alertMessage = "Profile updated successfully"
                            showAlert = true
                        case .failure(let error):
                            alertMessage = "Error updating profile: \(error.localizedDescription)"
                            showAlert = true
                        }
                    },
                    receiveValue: { _ in }
                )
            } catch {
                isLoading = false
                alertMessage = "Error updating profile: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

// MARK: - Preview Provider

extension ProfileEditView: PreviewProvider {
    static var previews: some View {
        let mockViewModel = ProfileViewModel(
            authService: AuthService(),
            appState: AppState()
        )
        ProfileEditView(viewModel: mockViewModel)
    }
}