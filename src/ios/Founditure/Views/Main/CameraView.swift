//
// CameraView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify camera usage description in Info.plist
// 2. Test camera functionality on physical devices
// 3. Verify CoreML model integration
// 4. Test memory usage during extended camera sessions
// 5. Configure analytics tracking for camera usage
// 6. Test offline functionality and local storage

import SwiftUI // iOS 14.0+
import AVFoundation // iOS 14.0+

/// Main camera view for furniture documentation with real-time AI recognition
/// Requirement: Mobile Applications - Implements native iOS camera functionality with offline-first architecture
struct CameraView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = CameraViewModel(
        coreMLService: CoreMLService(),
        imageProcessor: ImageProcessor(),
        storageService: StorageService<UIImage>(),
        appState: AppState()
    )
    @State private var showingImagePicker = false
    @State private var showingPermissionAlert = false
    @State private var isProcessing = false
    
    // MARK: - Constants
    
    private enum Constants {
        static let buttonSize: CGFloat = 72
        static let overlayOpacity: Double = 0.7
        static let animationDuration: Double = 0.3
        static let cornerRadius: CGFloat = 12
    }
    
    // MARK: - Body
    
    /// Requirement: Mobile Applications - Implements native iOS camera functionality
    var body: some View {
        ZStack {
            // Camera preview
            cameraPreview()
                .edgesIgnoringSafeArea(.all)
            
            // Recognition overlay
            if let result = viewModel.recognitionResult {
                recognitionOverlay(result: result)
            }
            
            // Controls overlay
            VStack {
                Spacer()
                
                // Camera controls
                HStack(spacing: 40) {
                    // Gallery button
                    Button(action: { showingImagePicker = true }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    // Capture button
                    captureButton()
                    
                    // Processing indicator or last capture
                    Group {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else if let image = viewModel.capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else {
                            Color.clear
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImages: .constant([]))
        }
        .alert(isPresented: $showingPermissionAlert) {
            Alert(
                title: Text("Camera Access Required"),
                message: Text("Please enable camera access in Settings to use this feature."),
                primaryButton: .default(Text("Settings"), action: openSettings),
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            setupCamera()
        }
    }
    
    // MARK: - View Components
    
    /// Creates the camera preview layer
    /// Requirement: Mobile Applications - Implements native iOS camera functionality
    private func cameraPreview() -> some View {
        GeometryReader { geometry in
            ZStack {
                if viewModel.isCameraActive {
                    CameraPreviewLayer(session: viewModel.captureSession)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    Color.black
                }
            }
        }
    }
    
    /// Creates the main capture button with feedback
    /// Requirement: Furniture documentation - Enables users to capture furniture items
    private func captureButton() -> some View {
        Button(action: captureImage) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                
                if isProcessing {
                    Circle()
                        .stroke(Color.blue, lineWidth: 4)
                        .frame(width: Constants.buttonSize - 8, height: Constants.buttonSize - 8)
                }
            }
        }
        .disabled(isProcessing || !viewModel.isCameraActive)
        .scaleEffect(isProcessing ? 0.9 : 1.0)
        .animation(.easeInOut(duration: Constants.animationDuration), value: isProcessing)
    }
    
    /// Displays real-time AI recognition results
    /// Requirement: AI/ML Infrastructure - Integrates real-time furniture recognition
    private func recognitionOverlay(result: MLResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detected Furniture")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(result.predictions, id: \.label) { prediction in
                HStack {
                    Text(prediction.label)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(prediction.confidence * 100))%")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.black.opacity(Constants.overlayOpacity))
        .cornerRadius(Constants.cornerRadius)
        .padding()
        .transition(.opacity)
    }
    
    // MARK: - Actions
    
    /// Sets up the camera session
    private func setupCamera() {
        viewModel.setupCamera()
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        showingPermissionAlert = true
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &viewModel.cancellables)
    }
    
    /// Captures and processes an image
    /// Requirement: AI/ML Infrastructure - Integrates real-time furniture recognition
    private func captureImage() {
        isProcessing = true
        
        viewModel.captureImage()
            .flatMap { _ in viewModel.recognizeFurniture() }
            .flatMap { _ in viewModel.saveProcessedImage() }
            .sink(
                receiveCompletion: { completion in
                    isProcessing = false
                    if case .failure = completion {
                        // Handle error
                    }
                },
                receiveValue: { _ in
                    // Handle success
                }
            )
            .store(in: &viewModel.cancellables)
    }
    
    /// Opens system settings
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}

// MARK: - Camera Preview Layer

/// UIKit wrapper for AVCaptureVideoPreviewLayer
private struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - Preview Provider

extension CameraView: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}