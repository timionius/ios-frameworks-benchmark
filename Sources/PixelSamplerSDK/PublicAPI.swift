// Sources/PixelSamplerSDK/PublicAPI.swift
import Foundation
import UIKit

@frozen
public struct PixelSamplerSDK {
    
    public static let shared = PixelSamplerSDK()
    
    private let coordinator = BenchmarkCoordinator.shared
    
    private init() {}
    
    // MARK: - Initialization
    
    public static func initialize() {
        shared.coordinator.markAppStart()
    }
    
    // MARK: - Main Entry Point
    
    public static func windowIsReady(_ window: UIWindow) {
        shared.coordinator.startSampling(window: window)
    }
    
    // MARK: - Event Marking (Optional)
    
    public func markEvent(_ event: BenchmarkEvent) {
        coordinator.markEvent(event)
    }
    
    // MARK: - Results
    
    public func getResults() -> BenchmarkResults? {
        return coordinator.getResults()
    }
    
    public var isComplete: Bool {
        return coordinator.isComplete
    }
}

// MARK: - Public Types

public enum BenchmarkEvent: String, CaseIterable {
    case applicationStart      = "APP_START"
    case frameworkEntry        = "FRAMEWORK_ENTRY"
    case renderComplete        = "RENDER_COMPLETE"
}

@frozen
public struct BenchmarkResults {
    public let totalTimeMs: Double
    public let details: [String: Double]
    
    public init(totalTimeMs: Double, details: [String: Double]) {
        self.totalTimeMs = totalTimeMs
        self.details = details
    }
}
