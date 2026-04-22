import Combine
import UIKit

final class BenchmarkCoordinator: ObservableObject {
    
    static let shared = BenchmarkCoordinator()
    
    @Published var events: [BenchmarkEvent: Double] = [:]
    
    private var appStartTime: Double = 0
    private var pixelSampler: PixelSampler?
    
    private init() {}
    
    func markAppStart() {
        guard appStartTime == 0 else { return }
        appStartTime = CACurrentMediaTime()
        events[.applicationStart] = 0
        PSLog("🚀 [BENCHMARK] APP_START: 0.000ms")
    }
    
    func markEvent(_ event: BenchmarkEvent) {
        let timestamp = CACurrentMediaTime()
        let relativeMs = (timestamp - appStartTime) * 1000
        events[event] = relativeMs
        PSLog("✅ [BENCHMARK] \(event.rawValue): \(String(format: "%.3f", relativeMs))ms")
    }
    
    // MARK: - Main Entry Point
    func startSampling(window: UIWindow) {
        guard let rootView = window.rootViewController?.view else {
            PSLog("⚠️ [BENCHMARK] No root view found")
            return
        }
        
        pixelSampler = PixelSampler()
        pixelSampler?.startSampling(on: rootView) { [weak self] lastMoveTime in
            guard let self = self else { return }
            let elapsed = (lastMoveTime - self.appStartTime) * 1000
            self.events[.renderComplete] = elapsed
            PSLog("\n✅ [BENCHMARK] Render complete")
            PSLog("✅ [BENCHMARK] Total time: \(String(format: "%.1f", elapsed))ms")
        }
    }
    
    // MARK: - Results
    func getResults() -> BenchmarkResults? {
        guard let renderComplete = events[.renderComplete] else { return nil }
        
        var details: [String: Double] = [:]
        for (event, timing) in events {
            details[event.rawValue] = timing
        }
        
        return BenchmarkResults(totalTimeMs: renderComplete, details: details)
    }
    
    // MARK: - For tests
    
#if DEBUG
    func reset() {
        self.appStartTime = 0
        self.events.removeAll()
        self.pixelSampler = nil
        PSLog("🧹 [BENCHMARK] Coordinator reset")
    }
#endif
}
