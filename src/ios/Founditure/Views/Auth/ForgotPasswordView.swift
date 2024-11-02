//
// ForgotPasswordView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure analytics tracking for password reset events
// 2. Set up proper error tracking integration
// 3. Verify email template configuration for reset instructions
// 4. Review rate limiting settings for password reset requests

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// SwiftUI view that provides password reset functionality
/// Requirement: User registration and authentication - Implements password reset functionality
struct ForgotPasswordView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = AuthViewModel(authService: AuthService())
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Body
    
    /// Main view body implementing the password reset interface
    /// Requirement: Authentication Flow - Handles password reset flow in the authentication process
    var body: some View {
        VStack(spacing: 20) {
            // App Logo
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.top, 40)
            
            // Header Text
            Text("Reset Password")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 20)
            
            // Instructions Text
            Text("Enter your email address and we'll send you instructions to reset your password.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            
            // Email Input Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 20)
            
            // Reset Password Button
            Button(action: resetPassword) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Reset Password")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal, 20)
            .disabled(isLoading || email.isEmpty)
            
            // Back to Login Button
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("Back to Login")
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Password Reset"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if !alertMessage.contains("error") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
        .padding()
    }
    
    // MARK: - Methods
    
    /// Handles password reset request submission
    /// Requirement: Privacy Controls - Implements secure password reset with proper validation
    private func resetPassword() {
        // Validate email input
        let validationResult = ValidationHelper.validateUserCredentials(email: email, password: "dummy")
        
        switch validationResult {
        case .success:
            isLoading = true
            
            // Call viewModel reset password method
            Task {
                do {
                    try await viewModel.resetPassword(email: email)
                    isLoading = false
                    alertMessage = "Password reset instructions have been sent to your email."
                    showAlert = true
                } catch {
                    isLoading = false
                    if let authError = error as? AuthenticationError {
                        alertMessage = authError.localizedDescription
                    } else {
                        alertMessage = "An error occurred while processing your request. Please try again."
                    }
                    showAlert = true
                }
            }
            
        case .failure(let error):
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

// MARK: - Preview Provider

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}