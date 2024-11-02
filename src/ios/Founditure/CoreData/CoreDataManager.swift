//
// CoreDataManager.swift
// Founditure
//
// HUMAN TASKS:
// 1. Create Core Data model file named "FounditureModel.xcdatamodeld"
// 2. Add necessary entities and attributes to the Core Data model
// 3. Configure proper data migration strategy for production
// 4. Set up proper Core Data store protection level
// 5. Verify Core Data model versioning is properly configured

// CoreData framework - iOS 14.0+
import CoreData
// Foundation framework - iOS 14.0+
import Foundation

// MARK: - Internal Dependencies
import Utils.Logger

// MARK: - Global Constants
private let CORE_DATA_MODEL_NAME = "FounditureModel"
private let SQLITE_STORE_NAME = "Founditure.sqlite"

/// A singleton manager class that handles all Core Data operations
/// Requirement: Local data persistence - Implements offline-first architecture with local data persistence
final class CoreDataManager {
    // MARK: - Properties
    
    /// Shared instance of CoreDataManager
    static let shared = CoreDataManager()
    
    /// The persistent container for the application
    private let persistentContainer: NSPersistentContainer
    
    /// The main managed object context
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    private init() {
        // Initialize persistent container with model name
        persistentContainer = NSPersistentContainer(name: CORE_DATA_MODEL_NAME)
        
        // Configure persistent store description
        let storeDescription = persistentContainer.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, 
                                  forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        storeDescription?.setOption(true as NSNumber, 
                                  forKey: NSPersistentHistoryTrackingKey)
        
        // Load persistent stores
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                Logger.log(
                    "Failed to load Core Data stack",
                    level: .fatal,
                    category: .storage,
                    error: error
                )
            }
        }
        
        // Set up main context
        context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Configure automatic merging from parent
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(managedObjectContextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
        
        Logger.log(
            "Core Data stack initialized successfully",
            level: .info,
            category: .storage
        )
    }
    
    // MARK: - Public Methods
    
    /// Saves changes in the managed object context
    /// Requirement: Data Management - Handles local database operations and data persistence
    /// - Returns: Success status of the save operation
    func saveContext() -> Bool {
        // Check if context has changes
        guard context.hasChanges else { return true }
        
        do {
            // Attempt to save context
            try context.save()
            Logger.log(
                "Core Data context saved successfully",
                level: .info,
                category: .storage
            )
            return true
        } catch {
            Logger.log(
                "Failed to save Core Data context",
                level: .error,
                category: .storage,
                error: error
            )
            return false
        }
    }
    
    /// Executes a task in a background context
    /// Requirement: Data Management - Handles local database operations and data persistence
    /// - Parameter block: The block to execute in the background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { backgroundContext in
            backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            // Execute provided block
            block(backgroundContext)
            
            // Save context if changes exist
            guard backgroundContext.hasChanges else { return }
            
            do {
                try backgroundContext.save()
                Logger.log(
                    "Background context saved successfully",
                    level: .info,
                    category: .storage
                )
            } catch {
                Logger.log(
                    "Failed to save background context",
                    level: .error,
                    category: .storage,
                    error: error
                )
            }
        }
    }
    
    /// Clears all data from Core Data storage
    /// Requirement: Data Management - Handles local database operations and data persistence
    /// - Returns: Success status of the clear operation
    func clearStorage() -> Bool {
        let entityNames = persistentContainer.managedObjectModel.entities.map { $0.name ?? "" }
        var success = true
        
        entityNames.forEach { entityName in
            // Create batch delete request for each entity
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            
            do {
                // Execute batch delete requests
                let result = try context.execute(batchDeleteRequest) as? NSBatchDeleteResult
                let changes: [AnyHashable: Any] = [
                    NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []
                ]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
            } catch {
                success = false
                Logger.log(
                    "Failed to clear entity: \(entityName)",
                    level: .error,
                    category: .storage,
                    error: error
                )
            }
        }
        
        // Save context
        success = success && saveContext()
        
        // Log operation result
        Logger.log(
            "Storage clear operation completed with status: \(success)",
            level: success ? .info : .error,
            category: .storage
        )
        
        return success
    }
    
    /// Handles Core Data model migrations
    /// Requirement: Data Management - Handles local database operations and data persistence
    /// - Returns: Success status of migration
    func handleMigration() -> Bool {
        do {
            // Check current model version
            guard let modelURL = Bundle.main.url(forResource: CORE_DATA_MODEL_NAME, withExtension: "momd"),
                  let sourceModel = NSManagedObjectModel(contentsOf: modelURL) else {
                throw NSError(domain: "CoreDataManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to load model"
                ])
            }
            
            // Compare with store metadata
            let coordinator = persistentContainer.persistentStoreCoordinator
            guard let storeURL = coordinator.persistentStores.first?.url else {
                throw NSError(domain: "CoreDataManager", code: -2, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to get store URL"
                ])
            }
            
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )
            
            // Perform migration if needed
            if !sourceModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
                try coordinator.migrateStore(
                    coordinator.persistentStores.first!,
                    to: storeURL,
                    options: nil,
                    withType: NSSQLiteStoreType
                )
            }
            
            Logger.log(
                "Core Data migration completed successfully",
                level: .info,
                category: .storage
            )
            return true
        } catch {
            Logger.log(
                "Core Data migration failed",
                level: .error,
                category: .storage,
                error: error
            )
            return false
        }
    }
    
    // MARK: - Private Methods
    
    @objc private func managedObjectContextDidSave(_ notification: Notification) {
        // Merge changes to main context if the saved context is not the main context
        guard let savedContext = notification.object as? NSManagedObjectContext,
              savedContext !== context else { return }
        
        context.perform {
            self.context.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}