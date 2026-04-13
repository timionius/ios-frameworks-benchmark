// Sources/PixelSamplerSDK/PublicAPI.swift
import Foundation
import UIKit

@frozen
public struct PixelSamplerSDK {
    
    public static let shared = PixelSamplerSDK()
    
    private let coordinator = BenchmarkCoordinator.shared
    
    private init() {}
    
    // MARK: - Initialization
    
    private static var isInitialized = false
    
    public static func initialize() {
        guard !isInitialized else { return }
        isInitialized = true
        shared.coordinator.markAppStart()
        print("🚀 [BENCHMARK] SDK initialized")
    }
    
    // MARK: - Window Tracking
    
    private static var hasStartedSampling = false
    
    public static func windowIsReady(_ window: UIWindow) {
        guard !hasStartedSampling else { return }
        guard let rootView = window.rootViewController?.view else {
            print("⚠️ [BENCHMARK] Window has no root view yet")
            return
        }
        
        hasStartedSampling = true
        
        // Ensure SDK is initialized
        initialize()
        
        shared.coordinator.markEvent(.windowReady)
        
        // Calculate sampling points
        let bounds = window.bounds
        let centerX = bounds.width / 2
        let imageSize: CGFloat = 100
        let spacing: CGFloat = 25
        let totalHeight = 3 * imageSize + 2 * spacing
        let startY = (bounds.height - totalHeight) / 2 + imageSize / 2
        
        let points = [
            CGPoint(x: centerX, y: startY),
            CGPoint(x: centerX, y: startY + imageSize + spacing),
            CGPoint(x: centerX, y: startY + 2 * (imageSize + spacing))
        ]
        
        print("📍 [BENCHMARK] Starting pixel sampling from window ready")
        shared.coordinator.startSampling(on: rootView, points: points, samplingSize: 4)
    }
    
    // MARK: - Event Marking
    
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
    case windowReady           = "WINDOW_READY"
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
