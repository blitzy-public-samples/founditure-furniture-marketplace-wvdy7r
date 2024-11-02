//
// ImagePicker.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify camera usage description is set in Info.plist
// 2. Verify photo library usage description is set in Info.plist
// 3. Test camera functionality on physical devices
// 4. Verify image size limits on different device types
// 5. Test memory usage with multiple image selections

// SwiftUI framework - iOS 14.0+
import SwiftUI
// PhotosUI framework - iOS 14.0+
import PhotosUI
// Internal dependencies
import Utils.ImageProcessor
import Utils.Constants.AppConstants

/// A SwiftUI view that provides image selection and capture functionality
/// Requirement: Mobile Applications - Provides native iOS image capture and selection functionality
struct ImagePicker: View {
    // MARK: - Properties
    @Binding var selectedImages: [UIImage]
    @State private var isShowingImagePicker: Bool = false
    @State private var isShowingCamera: Bool = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isProcessing: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    private let imageProcessor: ImageProcessor
    
    // MARK: - Initialization
    init(selectedImages: Binding<[UIImage]>) {
        self._selectedImages = selectedImages
        self.imageProcessor = ImageProcessor(options: ProcessingOptions(
            targetSize: CGSize(width: 1024, height: 1024),
            compressionQuality: 0.8,
            stripMetadata: true,
            enhanceImage: true
        ))
    }
    
    // MARK: - Body
    /// Requirement: Furniture documentation - Enables users to capture and select furniture images
    var body: some View {
        VStack(spacing: 16) {
            // Image selection buttons
            HStack(spacing: 20) {
                // Photo Library Button
                Button(action: {
                    sourceType = .photoLibrary
                    isShowingImagePicker = true
                }) {
                    VStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                        Text("Gallery")
                            .font(.caption)
                    }
                }
                
                // Camera Button (if available)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button(action: {
                        sourceType = .camera
                        isShowingCamera = true
                    }) {
                        VStack {
                            Image(systemName: "camera")
                                .font(.system(size: 24))
                            Text("Camera")
                                .font(.caption)
                        }
                    }
                }
            }
            .padding()
            
            // Selected images grid
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                // Delete button
                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Processing indicator
            if isProcessing {
                ProgressView("Processing image...")
                    .padding()
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePickerController(sourceType: sourceType, onImageSelected: processSelectedImage)
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Private Methods
    
    /// Processes a newly selected or captured image
    /// Requirement: Image Recognition - Captures and prepares images for furniture recognition processing
    private func processSelectedImage(_ image: UIImage) {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Validate image size
            guard let imageData = image.jpegData(compressionQuality: 1.0),
                  imageData.count <= App.maxImageSize else {
                showError(message: "Image size exceeds maximum allowed size")
                return
            }
            
            // Check image count limit
            guard selectedImages.count < App.maxImageCount else {
                showError(message: "Maximum number of images reached")
                return
            }
            
            // Process image for AI
            guard let processedImage = imageProcessor.prepareForAI(image) else {
                showError(message: "Failed to process image")
                return
            }
            
            // Optimize for upload
            guard let _ = imageProcessor.optimizeForUpload(processedImage) else {
                showError(message: "Failed to optimize image")
                return
            }
            
            DispatchQueue.main.async {
                selectedImages.append(processedImage)
                isProcessing = false
            }
        }
    }
    
    private func showError(message: String) {
        DispatchQueue.main.async {
            errorMessage = message
            showError = true
            isProcessing = false
        }
    }
}

// MARK: - ImagePickerController
/// UIKit wrapper for UIImagePickerController
private struct ImagePickerController: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        
        init(onImageSelected: @escaping (UIImage) -> Void) {
            self.onImageSelected = onImageSelected
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onImageSelected(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview Provider
struct ImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        ImagePicker(selectedImages: .constant([]))
    }
}