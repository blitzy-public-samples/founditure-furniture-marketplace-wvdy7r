//
// ImageProcessor.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify CoreML model is included in the app bundle
// 2. Configure proper memory limits for image processing
// 3. Set up proper cache cleanup policies
// 4. Verify camera permissions are properly configured in Info.plist
// 5. Test with various iOS devices to ensure optimal performance

// UIKit framework - iOS 14.0+
import UIKit
// CoreImage framework - iOS 14.0+
import CoreImage
// CoreML framework - iOS 14.0+
import CoreML

// MARK: - Internal Dependencies
import Utils.Logger

/// Configuration options for image processing
/// Requirement: Image Recognition - Provides configurable parameters for image processing
public struct ProcessingOptions {
    let targetSize: CGSize
    let compressionQuality: Float
    let stripMetadata: Bool
    let enhanceImage: Bool
    
    public init(
        targetSize: CGSize = CGSize(width: 224, height: 224),
        compressionQuality: Float = 0.8,
        stripMetadata: Bool = true,
        enhanceImage: Bool = true
    ) {
        self.targetSize = targetSize
        self.compressionQuality = compressionQuality
        self.stripMetadata = stripMetadata
        self.enhanceImage = enhanceImage
    }
}

/// Handles all image processing operations for furniture photos
/// Requirement: Image Recognition - Prepares images for TensorFlow model processing with MobileNetV3 architecture
public final class ImageProcessor {
    // MARK: - Properties
    private let targetSize: CGSize
    private let compressionQuality: Float
    private let context: CIContext
    
    // MARK: - Constants
    private enum Constants {
        static let defaultTargetSize = CGSize(width: 224, height: 224) // MobileNetV3 input size
        static let defaultCompressionQuality: Float = 0.8
        static let maxImageDimension: CGFloat = 4096
        static let minImageDimension: CGFloat = 224
    }
    
    // MARK: - Initialization
    public init(options: ProcessingOptions? = nil) {
        // Initialize CIContext for image processing
        self.context = CIContext(options: [
            .useSoftwareRenderer: false,
            .cacheIntermediates: true
        ])
        
        // Set default target size for ML processing
        self.targetSize = options?.targetSize ?? Constants.defaultTargetSize
        
        // Configure default compression quality
        self.compressionQuality = options?.compressionQuality ?? Constants.defaultCompressionQuality
        
        Logger.log(
            "ImageProcessor initialized with targetSize: \(targetSize), quality: \(compressionQuality)",
            level: .info,
            category: .storage
        )
    }
    
    // MARK: - Public Methods
    
    /// Prepares an image for AI model processing
    /// Requirement: Image Recognition - Prepares images for TensorFlow model processing
    public func prepareForAI(_ image: UIImage) -> UIImage? {
        Logger.log(
            "Preparing image for AI processing",
            level: .info,
            category: .storage
        )
        
        do {
            // Resize image to target dimensions
            guard let resizedImage = resize(image, to: targetSize) else {
                throw NSError(domain: "ImageProcessor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to resize image"])
            }
            
            // Convert color space to RGB
            guard let rgbImage = convertToRGBColorSpace(resizedImage) else {
                throw NSError(domain: "ImageProcessor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert color space"])
            }
            
            // Normalize pixel values
            guard let normalizedImage = normalizePixelValues(rgbImage) else {
                throw NSError(domain: "ImageProcessor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to normalize image"])
            }
            
            return normalizedImage
        } catch {
            Logger.log(
                "Failed to prepare image for AI",
                level: .error,
                category: .storage,
                error: error
            )
            return nil
        }
    }
    
    /// Optimizes image for network upload
    /// Requirement: Data Management - Handles image optimization and storage preparation
    public func optimizeForUpload(_ image: UIImage) -> Data? {
        Logger.log(
            "Optimizing image for upload",
            level: .info,
            category: .storage
        )
        
        do {
            // Resize image to appropriate dimensions
            let maxDimension = min(image.size.width, image.size.height, Constants.maxImageDimension)
            let targetSize = CGSize(width: maxDimension, height: maxDimension)
            
            guard let resizedImage = resize(image, to: targetSize) else {
                throw NSError(domain: "ImageProcessor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to resize image for upload"])
            }
            
            // Apply compression
            guard let imageData = resizedImage.jpegData(compressionQuality: CGFloat(compressionQuality)) else {
                throw NSError(domain: "ImageProcessor", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }
            
            return imageData
        } catch {
            Logger.log(
                "Failed to optimize image for upload",
                level: .error,
                category: .storage,
                error: error
            )
            return nil
        }
    }
    
    /// Extracts relevant metadata from furniture image
    /// Requirement: Data Management - Handles image metadata extraction
    public func extractMetadata(_ image: UIImage) -> [String: Any] {
        Logger.log(
            "Extracting image metadata",
            level: .info,
            category: .storage
        )
        
        var metadata: [String: Any] = [:]
        
        // Get image dimensions
        metadata["dimensions"] = [
            "width": image.size.width,
            "height": image.size.height,
            "scale": image.scale
        ]
        
        // Get image orientation
        metadata["orientation"] = image.imageOrientation.rawValue
        
        // Get device info
        metadata["device"] = [
            "model": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion
        ]
        
        // Get timestamp
        metadata["timestamp"] = Date().timeIntervalSince1970
        
        return metadata
    }
    
    /// Applies furniture-specific image enhancements
    /// Requirement: Image Recognition - Enhances images for better recognition
    public func applyEnhancements(_ image: UIImage) -> UIImage? {
        Logger.log(
            "Applying image enhancements",
            level: .info,
            category: .storage
        )
        
        guard let inputImage = CIImage(image: image) else { return nil }
        
        do {
            // Apply noise reduction
            let noiseReduction = inputImage.applyingFilter("CINoiseReduction", parameters: [
                kCIInputNoiseReductionAmountKey: 0.5
            ])
            
            // Enhance edges for furniture details
            let edges = noiseReduction.applyingFilter("CIUnsharpMask", parameters: [
                kCIInputRadiusKey: 2.5,
                kCIInputIntensityKey: 0.5
            ])
            
            // Adjust brightness and contrast
            let adjusted = edges.applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: 0.05,
                kCIInputContrastKey: 1.1,
                kCIInputSaturationKey: 1.1
            ])
            
            // Convert back to UIImage
            guard let outputImage = context.createCGImage(adjusted, from: adjusted.extent) else {
                throw NSError(domain: "ImageProcessor", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to create enhanced image"])
            }
            
            return UIImage(cgImage: outputImage)
        } catch {
            Logger.log(
                "Failed to apply image enhancements",
                level: .error,
                category: .storage,
                error: error
            )
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func resize(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    private func convertToRGBColorSpace(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage,
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        
        context.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height)))
        guard let convertedImage = context.makeImage() else { return nil }
        
        return UIImage(cgImage: convertedImage)
    }
    
    private func normalizePixelValues(_ image: UIImage) -> UIImage? {
        guard let inputImage = CIImage(image: image) else { return nil }
        
        let normalizedImage = inputImage.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1/255, y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1/255, z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1/255, w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
            "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
        ])
        
        guard let outputImage = context.createCGImage(normalizedImage, from: normalizedImage.extent) else { return nil }
        return UIImage(cgImage: outputImage)
    }
}