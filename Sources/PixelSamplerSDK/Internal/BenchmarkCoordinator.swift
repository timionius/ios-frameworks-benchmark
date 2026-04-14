import Combine
import UIKit

@usableFromInline
final class BenchmarkCoordinator: ObservableObject {
    
    @usableFromInline
    static let shared = BenchmarkCoordinator()
    
    @Published var events: [BenchmarkEvent: Double] = [:]
    @Published var isComplete = false
    
    private var appStartTime: Double = 0
    private var isSamplingComplete = false
    private var swiftUISampler: SwiftUIPixelSampler?
    private var flutterSampler: FlutterMetalSampler?
    
    private init() {}
    
    func markAppStart() {
        guard appStartTime == 0 else { return }
        appStartTime = CACurrentMediaTime()
        events[.applicationStart] = 0
        print("🚀 [BENCHMARK] APP_START: 0.000ms")
    }
    
    func markEvent(_ event: BenchmarkEvent) {
        let timestamp = CACurrentMediaTime()
        let relativeMs = (timestamp - appStartTime) * 1000
        print("✅ [BENCHMARK] \(event.rawValue): \(String(format: "%.3f", relativeMs))ms")
        events[event] = timestamp - appStartTime
    }
    
    // MARK: - Main Entry Point
    
    func startSampling(window: UIWindow) {
        guard let rootView = window.rootViewController?.view else {
            print("⚠️ [BENCHMARK] No root view found")
            return
        }
        
        let centerX = window.bounds.width / 2
        let centerY = window.bounds.height / 2
        let point = CGPoint(x: centerX, y: centerY)
        
        // Detect if this is Flutter (has FlutterView)
        if findFlutterView(in: rootView) != nil {
            print("📍 Flutter detected, using Metal sampling")
            startFlutterSampling(on: rootView)
        } else {
            print("📍 SwiftUI/UIKit detected, using CALayer sampling")
            startSwiftUISampling(on: rootView, at: point)
        }
    }
    
    // MARK: - Flutter Metal Sampling
    
    private func startFlutterSampling(on view: UIView) {
        flutterSampler = FlutterMetalSampler()
        flutterSampler?.startSampling(on: view) { [weak self] finalHash in
            guard let self = self else { return }
            let elapsed = (CACurrentMediaTime() - self.appStartTime) * 1000
            print("\n✅ Render complete")
            print("✅ Total time: \(String(format: "%.1f", elapsed))ms")
            self.events[.renderComplete] = elapsed / 1000
            self.isComplete = true
        }
    }
    
    // MARK: - SwiftUI/UIKit CALayer Sampling
    
    private func startSwiftUISampling(on view: UIView, at point: CGPoint) {
        swiftUISampler = SwiftUIPixelSampler(
            targetView: view,
            samplingPoints: [point],
            samplingSize: 4,
            requiredUnchangedFrames: 4
        )
        
        swiftUISampler?.startSampling { [weak self] firstStableTime in
            guard let self = self else { return }
            let elapsed = (CACurrentMediaTime() - self.appStartTime) * 1000
            print("\n✅ Render complete")
            print("✅ Total time: \(String(format: "%.1f", elapsed))ms")
            self.events[.renderComplete] = elapsed / 1000
            self.isComplete = true
        }
    }
    
    // MARK: - Flutter Detection Helper
    
    private func findFlutterView(in view: UIView) -> UIView? {
        let viewType = String(describing: type(of: view))
        if viewType.contains("FlutterView") {
            return view
        }
        for subview in view.subviews {
            if let found = findFlutterView(in: subview) {
                return found
            }
        }
        return nil
    }
    
    // MARK: - Results
    
    func getResults() -> BenchmarkResults? {
        guard let renderComplete = events[.renderComplete] else { return nil }
        
        let totalTimeMs = renderComplete * 1000
        
        var details: [String: Double] = [:]
        details["total_time"] = totalTimeMs
        
        if let frameworkEntry = events[.frameworkEntry] {
            details["framework_entry"] = frameworkEntry * 1000
            details["app_to_framework"] = frameworkEntry * 1000
        }
        
        return BenchmarkResults(totalTimeMs: totalTimeMs, details: details)
    }
}
