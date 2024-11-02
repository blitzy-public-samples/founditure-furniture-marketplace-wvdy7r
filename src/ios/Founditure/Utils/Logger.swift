//
// Logger.swift
// Founditure
//
// HUMAN TASKS:
// 1. Ensure write permissions are set for app's Documents directory
// 2. Configure proper log retention policies in production
// 3. Set up crash reporting service integration
// 4. Verify log file size limits are appropriate for the device
// 5. Configure proper file protection for log files

// Foundation framework - iOS 14.0+
import Foundation
// os.log framework - iOS 14.0+
import os.log

// MARK: - Internal Dependencies
import Utils.Constants.AppConstants
import Utils.Constants.ErrorMessages

// MARK: - Log Level Enumeration
/// Defines different severity levels for logging
/// Requirement: Error Handling - Provides structured logging levels for error tracking
public enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case fatal = "FATAL"
}

// MARK: - Log Category Enumeration
/// Categorizes logs for better organization
/// Requirement: Security Monitoring - Provides categorized logging for security events
public enum LogCategory: String {
    case network = "NETWORK"
    case auth = "AUTH"
    case furniture = "FURNITURE"
    case location = "LOCATION"
    case messages = "MESSAGES"
    case points = "POINTS"
    case storage = "STORAGE"
    case security = "SECURITY"
}

// MARK: - Global Constants
private let LOG_DATE_FORMAT = "yyyy-MM-dd HH:mm:ss.SSS"
private let MAX_LOG_SIZE_BYTES = 10 * 1024 * 1024 // 10MB
private let MAX_LOG_FILES = 5

// MARK: - Logger Class
/// Main logging class that handles all logging operations
/// Requirement: Security Monitoring - Implements logging for security events and monitoring
public final class Logger {
    // MARK: - Properties
    private static let fileManager = FileManager.default
    private static let logDirectory: String = {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("Logs").path
    }()
    private static let maxLogFiles = MAX_LOG_FILES
    private static let maxLogSize = MAX_LOG_SIZE_BYTES
    
    // MARK: - Initialization
    private init() {
        // Private initializer to prevent instantiation
    }
    
    // MARK: - Public Methods
    /// Logs a message with the specified level and category
    /// Requirement: Error Handling - Provides logging support for error tracking and debugging
    public static func log(
        _ message: String,
        level: LogLevel,
        category: LogCategory,
        error: Error? = nil
    ) {
        let timestamp = formatDate(Date())
        var logMessage = "[\(timestamp)] [\(level.rawValue)] [\(category.rawValue)] \(message)"
        
        if let error = error {
            logMessage += "\nError: \(error.localizedDescription)"
        }
        
        // Write to console in debug mode
        #if DEBUG
        print(logMessage)
        #endif
        
        // Write to system log
        let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.founditure.ios", category: category.rawValue)
        os_log("%{public}@", log: osLog, type: osLogType(for: level), logMessage)
        
        // Write to file
        writeToFile(logMessage)
        
        // Handle fatal errors
        if level == .fatal {
            handleFatalError(logMessage)
        }
        
        // Queue for offline sync if enabled
        if Features.offlineMode {
            queueForSync(logMessage)
        }
    }
    
    /// Clears all stored log files
    /// Returns: Success status of the operation
    public static func clearLogs() -> Bool {
        do {
            let logFiles = try fileManager.contentsOfDirectory(atPath: logDirectory)
            try logFiles.forEach { file in
                let filePath = (logDirectory as NSString).appendingPathComponent(file)
                try fileManager.removeItem(atPath: filePath)
            }
            return true
        } catch {
            log("Failed to clear logs: \(error.localizedDescription)",
                level: .error,
                category: .storage,
                error: error)
            return false
        }
    }
    
    /// Exports logs for debugging or support purposes
    /// Requirement: Offline-first architecture - Supports log export for debugging
    public static func exportLogs() -> Data? {
        do {
            let logFiles = try fileManager.contentsOfDirectory(atPath: logDirectory)
            var combinedLogs = Data()
            
            try logFiles.forEach { file in
                let filePath = (logDirectory as NSString).appendingPathComponent(file)
                let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
                combinedLogs.append(fileData)
            }
            
            return combinedLogs
        } catch {
            log("Failed to export logs: \(error.localizedDescription)",
                level: .error,
                category: .storage,
                error: error)
            return nil
        }
    }
    
    // MARK: - Private Methods
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = LOG_DATE_FORMAT
        return formatter.string(from: date)
    }
    
    private static func osLogType(for level: LogLevel) -> OSLogType {
        switch level {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .fatal: return .fault
        }
    }
    
    private static func writeToFile(_ message: String) {
        do {
            // Create logs directory if it doesn't exist
            if !fileManager.fileExists(atPath: logDirectory) {
                try fileManager.createDirectory(atPath: logDirectory,
                                             withIntermediateDirectories: true,
                                             attributes: nil)
            }
            
            // Rotate logs if needed
            try rotateLogs()
            
            // Write to current log file
            let currentLogPath = (logDirectory as NSString).appendingPathComponent("current.log")
            let messageData = (message + "\n").data(using: .utf8) ?? Data()
            
            if fileManager.fileExists(atPath: currentLogPath) {
                let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: currentLogPath))
                fileHandle.seekToEndOfFile()
                fileHandle.write(messageData)
                fileHandle.closeFile()
            } else {
                try messageData.write(to: URL(fileURLWithPath: currentLogPath))
            }
        } catch {
            print("Failed to write to log file: \(error.localizedDescription)")
        }
    }
    
    private static func rotateLogs() throws {
        let currentLogPath = (logDirectory as NSString).appendingPathComponent("current.log")
        
        // Check if current log file exists and exceeds size limit
        if fileManager.fileExists(atPath: currentLogPath) {
            let attributes = try fileManager.attributesOfItem(atPath: currentLogPath)
            let fileSize = attributes[.size] as? Int ?? 0
            
            if fileSize > maxLogSize {
                // Rotate existing archived logs
                for index in (1...maxLogFiles-1).reversed() {
                    let oldPath = (logDirectory as NSString).appendingPathComponent("log.\(index).archive")
                    let newPath = (logDirectory as NSString).appendingPathComponent("log.\(index + 1).archive")
                    
                    if fileManager.fileExists(atPath: oldPath) {
                        if index == maxLogFiles - 1 {
                            try fileManager.removeItem(atPath: oldPath)
                        } else {
                            try fileManager.moveItem(atPath: oldPath, toPath: newPath)
                        }
                    }
                }
                
                // Archive current log
                let archivePath = (logDirectory as NSString).appendingPathComponent("log.1.archive")
                try fileManager.moveItem(atPath: currentLogPath, toPath: archivePath)
            }
        }
    }
    
    private static func handleFatalError(_ message: String) {
        // Ensure log is written before potential crash
        writeToFile("FATAL ERROR: \(message)")
        
        #if DEBUG
        fatalError(message)
        #else
        // In production, gracefully handle fatal errors
        DispatchQueue.main.async {
            // Notify user of error
            print("Fatal error occurred: \(message)")
            // Additional crash reporting could be added here
        }
        #endif
    }
    
    private static func queueForSync(_ message: String) {
        // Implement offline sync queue for logs
        // This would typically involve storing logs in Core Data or similar
        // and syncing when connectivity is restored
    }
}