//
// NetworkMonitor.swift
// Founditure
//
// HUMAN TASKS:
// 1. Verify Network framework capabilities are enabled in project settings
// 2. Configure background execution permissions for network monitoring
// 3. Set up proper entitlements for network access
// 4. Verify minimum iOS version (14.0) is set in project settings

// Network framework - iOS 14.0+
import Network
// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Internal dependencies
import Utils.Logger
import Utils.Constants.AppConstants

// MARK: - Connection Type Enumeration
/// Defines different types of network connections
/// Requirement: Network Security - Monitors network security and connection status
public enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
}

// MARK: - Connection Quality Enumeration
/// Defines network connection quality levels
/// Requirement: System Health Metrics - Provides network performance metrics
public enum ConnectionQuality {
    case high
    case medium
    case low
    case poor
}

// MARK: - Network Metrics Structure
/// Structure containing network performance metrics
/// Requirement: System Health Metrics - Provides network reliability metrics
public struct NetworkMetrics {
    public let latency: Double
    public let bandwidth: Double
    public let signalStrength: Int
    public let quality: ConnectionQuality
}

// MARK: - Network Monitor Class
/// Main class responsible for monitoring network connectivity and providing status updates
/// Requirement: Offline-first architecture - Implements offline-first architecture by monitoring network connectivity
@available(iOS 14.0, *)
public final class NetworkMonitor {
    // MARK: - Private Properties
    private let pathMonitor: NWPathMonitor
    private let queue: DispatchQueue
    
    // MARK: - Public Properties
    private(set) var isConnected: CurrentValueSubject<Bool, Never>
    private(set) var connectionType: CurrentValueSubject<ConnectionType, Never>
    private(set) var connectionQuality: CurrentValueSubject<ConnectionQuality, Never>
    
    // MARK: - Initialization
    public init() {
        // Initialize dispatch queue for network monitoring
        self.queue = DispatchQueue(label: "\(APP_BUNDLE_ID).networkmonitor", qos: .utility)
        
        // Create NWPathMonitor instance
        self.pathMonitor = NWPathMonitor()
        
        // Initialize status publishers
        self.isConnected = CurrentValueSubject<Bool, Never>(false)
        self.connectionType = CurrentValueSubject<ConnectionType, Never>(.unknown)
        self.connectionQuality = CurrentValueSubject<ConnectionQuality, Never>(.poor)
        
        // Set up network monitoring
        self.pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.updateConnectionStatus(path)
        }
    }
    
    // MARK: - Public Methods
    /// Starts monitoring network connectivity
    /// Requirement: Network Security - Monitors connection status for secure communications
    public func startMonitoring() {
        pathMonitor.start(queue: queue)
        Logger.log("Network monitoring started", level: .info, category: .network)
    }
    
    /// Stops monitoring network connectivity
    public func stopMonitoring() {
        pathMonitor.cancel()
        Logger.log("Network monitoring stopped", level: .info, category: .network)
    }
    
    /// Retrieves current network connection metrics
    /// Requirement: System Health Metrics - Provides network performance and reliability metrics
    public func getConnectionMetrics() -> NetworkMetrics {
        let path = pathMonitor.currentPath
        
        // Calculate metrics based on current path
        let latency = calculateLatency(path)
        let bandwidth = calculateBandwidth(path)
        let signalStrength = calculateSignalStrength(path)
        let quality = determineConnectionQuality(latency: latency, bandwidth: bandwidth)
        
        return NetworkMetrics(
            latency: latency,
            bandwidth: bandwidth,
            signalStrength: signalStrength,
            quality: quality
        )
    }
    
    // MARK: - Private Methods
    /// Updates connection status based on network path
    private func updateConnectionStatus(_ path: NWPath) {
        // Update connection status
        isConnected.send(path.status == .satisfied)
        
        // Determine connection type
        let type: ConnectionType
        if path.usesInterfaceType(.wifi) {
            type = .wifi
        } else if path.usesInterfaceType(.cellular) {
            type = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            type = .ethernet
        } else {
            type = .unknown
        }
        connectionType.send(type)
        
        // Evaluate connection quality
        let metrics = getConnectionMetrics()
        connectionQuality.send(metrics.quality)
        
        // Log status changes
        Logger.log(
            "Network status updated - Connected: \(path.status == .satisfied), Type: \(type)",
            level: .info,
            category: .network
        )
        
        // Handle offline mode if needed
        if !isConnected.value && Features.offlineMode {
            Logger.log(
                "Network disconnected - Enabling offline mode",
                level: .warning,
                category: .network
            )
        }
    }
    
    /// Calculates network latency from path
    private func calculateLatency(_ path: NWPath) -> Double {
        // In a real implementation, this would use path.gatherMetrics()
        // For now, return an estimated value based on interface type
        switch path.status {
        case .satisfied:
            return path.usesInterfaceType(.wifi) ? 20.0 : 50.0
        default:
            return 1000.0
        }
    }
    
    /// Calculates network bandwidth from path
    private func calculateBandwidth(_ path: NWPath) -> Double {
        // In a real implementation, this would use path.gatherMetrics()
        // For now, return an estimated value based on interface type
        switch path.status {
        case .satisfied:
            if path.usesInterfaceType(.wifi) {
                return 100.0 // Mbps
            } else if path.usesInterfaceType(.cellular) {
                return 50.0 // Mbps
            } else {
                return 1000.0 // Mbps for ethernet
            }
        default:
            return 0.0
        }
    }
    
    /// Calculates signal strength from path
    private func calculateSignalStrength(_ path: NWPath) -> Int {
        // In a real implementation, this would use platform APIs
        // For now, return an estimated value based on path status
        switch path.status {
        case .satisfied:
            return path.usesInterfaceType(.wifi) ? 75 : 60
        default:
            return 0
        }
    }
    
    /// Determines connection quality based on metrics
    private func determineConnectionQuality(latency: Double, bandwidth: Double) -> ConnectionQuality {
        if latency < 50 && bandwidth > 100 {
            return .high
        } else if latency < 100 && bandwidth > 50 {
            return .medium
        } else if latency < 200 && bandwidth > 10 {
            return .low
        } else {
            return .poor
        }
    }
}