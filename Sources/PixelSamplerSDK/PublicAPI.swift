import Foundation
import UIKit

public final class PixelSamplerSDK {
    
    public static let shared = PixelSamplerSDK()
    
    private let coordinator = BenchmarkCoordinator.shared
    
    private init() {}
    
    // MARK: - Initialization
    
    public static func initialize() {
        shared.coordinator.markAppStart()
    }
    
    // MARK: - Main Entry Point
    
    @MainActor
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
}

// MARK: - Public Types

public enum BenchmarkEvent: String, CaseIterable {
    case applicationStart      = "APP_START"
    case frameworkEntry        = "FRAMEWORK_ENTRY"
    case renderComplete        = "RENDER_COMPLETE"
}

@frozen
public struct BenchmarkResults: Encodable {
    public let totalTimeMs: Double
    public let details: [String: Double]
    public let timestamp: Date
    
    public init(totalTimeMs: Double, details: [String: Double]) {
        self.totalTimeMs = totalTimeMs
        self.details = details
        self.timestamp = Date()
    }
    
    public func timeForEvent(_ event: BenchmarkEvent) -> Double? {
        return details[event.rawValue]
    }
    
    public var jsonRepresentation: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
