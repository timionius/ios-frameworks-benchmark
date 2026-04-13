import Combine
import UIKit

@usableFromInline
final class BenchmarkCoordinator: ObservableObject {
    
    @usableFromInline
    static let shared = BenchmarkCoordinator()
    
    @Published var events: [BenchmarkEvent: Double] = [:]
    @Published var isComplete = false
    
    private var appStartTime: Double = 0
    private var pixelSampler: PixelSampler?
    
    private init() {}
    
    func markAppStart() {
        guard appStartTime == 0 else { return }
        appStartTime = CACurrentMediaTime()
        events[.applicationStart] = 0
        print("🚀 [BENCHMARK] APP_START: 0.000ms")
    }
    
    func startSampling(on view: UIView, points: [CGPoint], samplingSize: Int = 4) {
        print("📍 [BENCHMARK] Starting pixel sampling (size: \(samplingSize)x\(samplingSize))")
        
        pixelSampler = PixelSampler(
            targetView: view,
            samplingPoints: points,
            samplingSize: samplingSize,
            requiredUnchangedFrames: 4
        )
        
        pixelSampler?.startSampling { [weak self] firstStableFrameTime in
            guard let self = self else { return }
            
            let relativeMs = (firstStableFrameTime - self.appStartTime) * 1000
            
            DispatchQueue.main.async {
                self.events[.renderComplete] = firstStableFrameTime - self.appStartTime
                print("✅ [BENCHMARK] RENDER_COMPLETE: \(String(format: "%.3f", relativeMs))ms")
                self.isComplete = true
                self.printResults()
            }
        }
    }
    
    func markEvent(_ event: BenchmarkEvent) {
        let timestamp = CACurrentMediaTime()
        let relativeMs = (timestamp - appStartTime) * 1000
        
        DispatchQueue.main.async {
            self.events[event] = timestamp - self.appStartTime
            print("✅ [BENCHMARK] \(event.rawValue): \(String(format: "%.3f", relativeMs))ms")
        }
    }
    
    private func printResults() {
        guard let renderComplete = events[.renderComplete] else {
            print("⚠️ [BENCHMARK] Cannot print results - missing events")
            return
        }
        
        let totalTime = renderComplete * 1000
        
        print("\n" + String(repeating: "═", count: 55))
        print("📊 BENCHMARK RESULTS")
        print(String(repeating: "═", count: 55))
        
        if let frameworkEntry = events[.frameworkEntry] {
            print("  APP_START → FRAMEWORK:        \(String(format: "%7.3f", frameworkEntry * 1000))ms")
        }
        
        print("  ─────────────────────────────────────────")
        print("  RENDER COMPLETE:               \(String(format: "%7.3f", totalTime))ms")
        print(String(repeating: "═", count: 55))
    }
    
    func getResults() -> BenchmarkResults? {
        guard let renderComplete = events[.renderComplete] else { return nil }
        
        let totalTimeMs = renderComplete * 1000
        
        var details: [String: Double] = [:]
        details["total_time"] = totalTimeMs
        
        if let frameworkEntry = events[.frameworkEntry] {
            details["framework_entry"] = frameworkEntry * 1000
            details["app_to_framework"] = frameworkEntry * 1000
        }
        
        return BenchmarkResults(
            totalTimeMs: totalTimeMs,
            details: details
        )
    }
}
