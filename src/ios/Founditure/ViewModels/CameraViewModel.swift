//
// CameraViewModel.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure camera permissions in Info.plist
// 2. Set up proper memory management for camera session
// 3. Configure CoreML model versioning
// 4. Set up analytics tracking for camera usage
// 5. Configure proper error tracking integration

import Combine // iOS 14.0+
import AVFoundation // iOS 14.0+
import UIKit // iOS 14.0+

// Internal dependencies
import Protocols.ViewModelProtocol
import Services.CoreMLService
import Utils.ImageProcessor
import Services.StorageService

/// ViewModel responsible for managing camera functionality and furniture recognition
/// Requirement: Mobile Applications - Implements native iOS camera functionality with offline-first architecture
@MainActor
final class CameraViewModel: ViewModelProtocol {
    // MARK: - Published Properties
    
    @Published private(set) var capturedImage: UIImage?
    @Published private(set) var recognitionResult: MLResult?
    @Published var isProcessing: Bool = false
    @Published var isCameraActive: Bool = false
    
    // MARK: - Private Properties
    
    private let coreMLService: CoreMLService
    private let imageProcessor: ImageProcessor
    private let storageService: StorageService<UIImage>
    private var captureSession: AVCaptureSession
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - ViewModelProtocol Properties
    
    var isLoading: Bool = false
    var error: Error?
    var appState: AppState
    
    // MARK: - Constants
    
    private enum Constants {
        static let imageQuality: Float = 0.9
        static let processingTimeout: TimeInterval = 30
        static let storageKey = "captured_furniture_image"
    }
    
    // MARK: - Initialization
    
    init(
        coreMLService: CoreMLService,
        imageProcessor: ImageProcessor,
        storageService: StorageService<UIImage>,
        appState: AppState
    ) {
        self.coreMLService = coreMLService
        self.imageProcessor = imageProcessor
        self.storageService = storageService
        self.appState = appState
        self.captureSession = AVCaptureSession()
        
        super.init()
        setupSubscriptions()
    }
    
    // MARK: - Public Methods
    
    /// Sets up and configures the camera capture session
    /// Requirement: Mobile Applications - Implements native iOS camera functionality
    func setupCamera() -> AnyPublisher<Bool, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "CameraViewModel", code: -1)))
                return
            }
            
            // Check camera authorization status
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.configureCaptureSession(promise: promise)
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.configureCaptureSession(promise: promise)
                    } else {
                        promise(.failure(NSError(domain: "CameraViewModel", code: -2)))
                    }
                }
            default:
                promise(.failure(NSError(domain: "CameraViewModel", code: -3)))
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Captures an image from the camera and processes it
    /// Requirement: Mobile Applications - Implements offline-first architecture
    func captureImage() -> AnyPublisher<UIImage, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "CameraViewModel", code: -1)))
                return
            }
            
            self.isProcessing = true
            
            guard let videoOutput = AVCapturePhotoOutput() else {
                promise(.failure(NSError(domain: "CameraViewModel", code: -4)))
                return
            }
            
            let settings = AVCapturePhotoSettings()
            videoOutput.capturePhoto(with: settings) { photoData, error in
                if let error = error {
                    self.isProcessing = false
                    promise(.failure(error))
                    return
                }
                
                guard let imageData = photoData?.fileDataRepresentation(),
                      let capturedImage = UIImage(data: imageData) else {
                    self.isProcessing = false
                    promise(.failure(NSError(domain: "CameraViewModel", code: -5)))
                    return
                }
                
                // Process and store the captured image
                self.processAndStoreImage(capturedImage)
                    .sink(
                        receiveCompletion: { completion in
                            self.isProcessing = false
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { processedImage in
                            self.capturedImage = processedImage
                            promise(.success(processedImage))
                        }
                    )
                    .store(in: &self.cancellables)
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    /// Processes captured image for furniture recognition
    /// Requirement: AI/ML Infrastructure - Integrates with on-device ML processing for furniture recognition
    func recognizeFurniture() -> AnyPublisher<MLResult, Error> {
        guard let image = capturedImage else {
            return Fail(error: NSError(domain: "CameraViewModel", code: -6))
                .eraseToAnyPublisher()
        }
        
        self.isProcessing = true
        
        return coreMLService.recognizeFurniture(image: image)
            .timeout(.seconds(Constants.processingTimeout), scheduler: DispatchQueue.main)
            .handleEvents(
                receiveOutput: { [weak self] result in
                    self?.recognitionResult = result
                },
                receiveCompletion: { [weak self] _ in
                    self?.isProcessing = false
                }
            )
            .eraseToAnyPublisher()
    }
    
    /// Saves processed image and recognition results
    /// Requirement: Mobile Applications - Implements offline-first architecture
    func saveProcessedImage() -> AnyPublisher<Bool, Error> {
        guard let image = capturedImage else {
            return Fail(error: NSError(domain: "CameraViewModel", code: -7))
                .eraseToAnyPublisher()
        }
        
        return storageService.save(
            image,
            key: "\(Constants.storageKey)_\(UUID().uuidString)",
            storageType: .coreData
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func configureCaptureSession(promise: @escaping (Result<Bool, Error>) -> Void) {
        captureSession.beginConfiguration()
        
        // Configure camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            promise(.failure(NSError(domain: "CameraViewModel", code: -8)))
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        // Configure photo output
        let output = AVCapturePhotoOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        }
        
        captureSession.commitConfiguration()
        
        // Start capture session
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            self?.isCameraActive = true
            promise(.success(true))
        }
    }
    
    private func processAndStoreImage(_ image: UIImage) -> AnyPublisher<UIImage, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "CameraViewModel", code: -9)))
                return
            }
            
            // Prepare image for AI processing
            guard let processedImage = self.imageProcessor.prepareForAI(image) else {
                promise(.failure(NSError(domain: "CameraViewModel", code: -10)))
                return
            }
            
            // Apply enhancements
            guard let enhancedImage = self.imageProcessor.applyEnhancements(processedImage) else {
                promise(.failure(NSError(domain: "CameraViewModel", code: -11)))
                return
            }
            
            promise(.success(enhancedImage))
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - ViewModelProtocol Methods
    
    func handleError(_ error: Error) {
        self.error = error
        self.isProcessing = false
        self.isLoading = false
    }
    
    func setupSubscriptions() {
        // Monitor camera authorization changes
        NotificationCenter.default.publisher(for: .AVCaptureDeviceWasConnected)
            .sink { [weak self] _ in
                self?.setupCamera()
                    .sink(
                        receiveCompletion: { _ in },
                        receiveValue: { _ in }
                    )
                    .store(in: &self!.cancellables)
            }
            .store(in: &cancellables)
        
        // Monitor app state changes
        appState.objectWillChange
            .sink { [weak self] _ in
                if self?.appState.isOffline == true {
                    self?.captureSession.stopRunning()
                    self?.isCameraActive = false
                }
            }
            .store(in: &cancellables)
    }
    
    func cleanUp() {
        cancellables.removeAll()
        captureSession.stopRunning()
        isCameraActive = false
    }
}