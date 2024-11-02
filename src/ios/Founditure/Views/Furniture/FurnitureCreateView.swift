//
// FurnitureCreateView.swift
// Founditure
//
// HUMAN TASKS:
// 1. Configure CoreML model integration for furniture recognition
// 2. Set up S3 bucket permissions for furniture image storage
// 3. Configure location services permissions in Info.plist
// 4. Set up appropriate image compression settings
// 5. Configure furniture listing expiration notifications

import SwiftUI // iOS 14.0+
import Combine // iOS 14.0+
import CoreLocation // iOS 14.0+

/// SwiftUI view that provides the user interface for creating new furniture listings
/// Requirement: Furniture documentation and discovery - Enables users to create and document new furniture listings
@available(iOS 14.0, *)
struct FurnitureCreateView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: FurnitureViewModel
    @State private var selectedImages: [UIImage] = []
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: FurnitureCategory = .other
    @State private var condition: FurnitureCondition = .good
    @State private var location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    @State private var privacyZone: PrivacyZoneType = .approximate
    @State private var isLoading: Bool = false
    @State private var showingImagePicker: Bool = false
    @State private var showingLocationPicker: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    // Alert states
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    
    // MARK: - Initialization
    
    init(viewModel: FurnitureViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Image Section
                // Requirement: Furniture documentation and discovery - Enables image capture for furniture listings
                Section(header: Text("Photos")) {
                    VStack {
                        ImagePicker(selectedImages: $selectedImages)
                            .frame(height: 200)
                        
                        Text("Add up to 5 photos")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // MARK: - Basic Information Section
                // Requirement: Furniture documentation and discovery - Captures essential furniture details
                Section(header: Text("Basic Information")) {
                    TextField("Title", text: $title)
                        .textContentType(.none)
                        .disableAutocorrection(true)
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // MARK: - Category and Condition Section
                // Requirement: Furniture documentation and discovery - Captures furniture classification
                Section(header: Text("Details")) {
                    Picker("Category", selection: $category) {
                        ForEach([FurnitureCategory.seating,
                                .tables,
                                .storage,
                                .beds,
                                .lighting,
                                .decor,
                                .outdoor,
                                .other], id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                    
                    Picker("Condition", selection: $condition) {
                        ForEach([FurnitureCondition.likeNew,
                                .good,
                                .fair,
                                .needsRepair,
                                .forParts], id: \.self) { condition in
                            Text(condition.rawValue.capitalized).tag(condition)
                        }
                    }
                }
                
                // MARK: - Location Section
                // Requirement: Location-based search - Integrates location selection for furniture listings
                Section(header: Text("Location")) {
                    Button(action: {
                        showingLocationPicker = true
                    }) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                            Text("Select Location")
                            Spacer()
                            if location.latitude != 0 && location.longitude != 0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                // MARK: - Submit Button Section
                Section {
                    Button(action: createListing) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Listing")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!validateInput() || isLoading)
                    .buttonStyle(BorderlessButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(validateInput() ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .navigationTitle("Create Listing")
            .navigationBarItems(leading: cancelButton)
            .sheet(isPresented: $showingLocationPicker) {
                LocationPicker(
                    selectedLocation: $location,
                    searchRadius: .constant(5000),
                    privacyZone: $privacyZone
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Private Views
    
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // MARK: - Private Methods
    
    /// Creates a new furniture listing
    /// Requirement: Furniture documentation and discovery - Handles furniture listing creation
    private func createListing() {
        guard validateInput() else { return }
        
        isLoading = true
        
        // Create furniture object
        let furniture = Furniture(
            title: title,
            description: description,
            category: category,
            condition: condition,
            location: Location(
                latitude: location.latitude,
                longitude: location.longitude,
                privacyZone: privacyZone
            ),
            userId: viewModel.appState.currentUser?.id ?? UUID()
        )
        
        // Convert images to Data
        let imageDataArray = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
        
        // Create furniture listing
        viewModel.createFurnitureListing(furniture: furniture, images: imageDataArray)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    switch completion {
                    case .finished:
                        presentationMode.wrappedValue.dismiss()
                    case .failure(let error):
                        showAlert = true
                        alertTitle = "Error"
                        alertMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &Set<AnyCancellable>())
    }
    
    /// Validates user input before submission
    /// Requirement: Furniture documentation and discovery - Ensures data quality
    private func validateInput() -> Bool {
        // Check title
        guard title.count >= 3 && title.count <= 100 else { return false }
        
        // Check description
        guard description.count >= 10 && description.count <= 1000 else { return false }
        
        // Check images
        guard !selectedImages.isEmpty && selectedImages.count <= 5 else { return false }
        
        // Check location
        guard location.latitude != 0 && location.longitude != 0 else { return false }
        
        return true
    }
}

// MARK: - Preview Provider

struct FurnitureCreateView_Previews: PreviewProvider {
    static var previews: some View {
        FurnitureCreateView(viewModel: FurnitureViewModel(appState: AppState()))
    }
}