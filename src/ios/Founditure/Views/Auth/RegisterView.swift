//
// RegisterView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure analytics tracking for registration events
// 2. Set up proper error tracking integration
// 3. Verify accessibility labels and hints are properly set
// 4. Review form validation rules with security team

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// SwiftUI view that implements the user registration screen
/// Requirement: User registration and authentication - Implements user registration interface
@MainActor
struct RegisterView: View {
    // MARK: - View Model
    
    @StateObject private var viewModel = AuthViewModel(authService: AuthService())
    
    // MARK: - State Properties
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var fullName: String = ""
    @State private var showingAlert: Bool = false
    
    // MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    // MARK: - Body
    
    /// Main view body implementing the registration form
    /// Requirement: User registration and authentication - Implements user registration interface
    var body: some View {
        NavigationView {
            ZStack {
                // Form content
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 40)
                        
                        // Form fields
                        VStack(spacing: 16) {
                            // Full Name field
                            // Requirement: Privacy controls - Handles user data input
                            TextField("Full Name", text: $fullName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.name)
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                                .padding(.horizontal)
                            
                            // Email field
                            // Requirement: Privacy controls - Handles user data input
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(.horizontal)
                            
                            // Password field
                            // Requirement: Privacy controls - Handles user data input
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.newPassword)
                                .padding(.horizontal)
                            
                            // Confirm Password field
                            // Requirement: Privacy controls - Handles user data input
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.newPassword)
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                        
                        // Register button
                        Button(action: register) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Register")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .disabled(viewModel.isLoading)
                        
                        // Login link
                        HStack {
                            Text("Already have an account?")
                            Button("Login") {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        .padding(.top)
                    }
                    .padding()
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        )
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Registration Error"),
                    message: Text(viewModel.error?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles the registration process
    /// Requirement: Input validation - Validates user input before submission
    private func register() {
        // Validate input
        let validationResult = validateInput()
        
        switch validationResult {
        case .success:
            // Attempt registration
            Task {
                do {
                    let publisher = viewModel.register(
                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password,
                        fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    
                    _ = try await publisher.async()
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    showingAlert = true
                }
            }
        case .failure(let error):
            viewModel.error = error
            showingAlert = true
        }
    }
    
    /// Validates user input before submission
    /// Requirement: Input validation - Validates user input before submission
    private func validateInput() -> Result<Void, ValidationError> {
        // Check for empty fields
        guard !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(.init(ValidationError.invalidName))
        }
        
        // Validate credentials using ValidationHelper
        let credentialsResult = ValidationHelper.validateUserCredentials(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        
        guard case .success = credentialsResult else {
            return credentialsResult
        }
        
        // Validate password confirmation
        guard password == confirmPassword else {
            return .failure(.init(AuthenticationError.weakPassword))
        }
        
        return .success(())
    }
}

// MARK: - Preview Provider

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}