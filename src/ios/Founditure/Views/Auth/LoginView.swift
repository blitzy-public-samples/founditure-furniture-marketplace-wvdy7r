//
// LoginView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure proper analytics tracking for login events
// 2. Set up error tracking integration
// 3. Configure biometric authentication if required
// 4. Verify accessibility compliance
// 5. Set up proper keyboard handling for text fields

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+

/// SwiftUI view that implements the user login screen with email and password authentication
/// Requirement: User registration and authentication - Implements user login interface with email and password authentication
struct LoginView: View {
    // MARK: - View Model
    
    @StateObject private var viewModel = AuthViewModel(authService: AuthService())
    
    // MARK: - State Properties
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isShowingError: Bool = false
    @Environment(\.presentationMode) private var presentationMode
    
    // MARK: - Constants
    
    private enum Constants {
        static let spacing: CGFloat = 20
        static let cornerRadius: CGFloat = 10
        static let buttonHeight: CGFloat = 50
        static let logoSize: CGFloat = 120
    }
    
    // MARK: - Body
    
    /// Builds the login view hierarchy
    /// Requirement: Mobile-first platform - Implements native iOS login interface using SwiftUI
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Constants.spacing) {
                    // App Logo
                    Image("app_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: Constants.logoSize, height: Constants.logoSize)
                        .padding(.top, Constants.spacing * 2)
                    
                    // Email Field
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("emailTextField")
                    
                    // Password Field
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                        .accessibilityIdentifier("passwordTextField")
                    
                    // Login Button
                    Button(action: handleLogin) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Log In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(height: Constants.buttonHeight)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.cornerRadius)
                    .disabled(viewModel.isLoading)
                    .accessibilityIdentifier("loginButton")
                    
                    // Forgot Password Link
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password?")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                    
                    // Register Account Link
                    NavigationLink(destination: RegisterView()) {
                        Text("Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 5)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .alert(isPresented: $isShowingError) {
                Alert(
                    title: Text("Login Error"),
                    message: Text(viewModel.error?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onReceive(viewModel.$authState) { state in
            handleAuthStateChange(state)
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles the login button tap action
    /// Requirement: Authentication Flow - Provides user interface for authentication flow
    private func handleLogin() {
        // Validate input credentials
        let validationResult = ValidationHelper.validateUserCredentials(
            email: email,
            password: password
        )
        
        switch validationResult {
        case .success:
            // Attempt login
            viewModel.login(email: email, password: password)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure = completion {
                            isShowingError = true
                        }
                    },
                    receiveValue: { _ in
                        // Login successful, handled by authState observer
                    }
                )
                .store(in: &viewModel.cancellables)
            
        case .failure(let error):
            viewModel.error = error
            isShowingError = true
        }
    }
    
    /// Handles changes in authentication state
    /// Requirement: Authentication Flow - Provides user interface for authentication flow
    private func handleAuthStateChange(_ state: AuthState) {
        switch state {
        case .authenticated:
            // Dismiss login view and navigate to main app interface
            presentationMode.wrappedValue.dismiss()
            
        case .error:
            isShowingError = true
            
        case .unauthenticated:
            // Reset form if needed
            break
        }
    }
}

// MARK: - Preview Provider

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}