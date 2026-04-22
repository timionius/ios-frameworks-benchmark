import UIKit
import Metal

public class PixelSampler {
    
    private weak var targetView: UIView?
    private var displayLink: CADisplayLink?
    
    // Callbacks & State
    private var completion: ((Double) -> Void)?
    private var startTime: CFTimeInterval = 0
    private var sampleRenderStartTime: CFTimeInterval = 0
    private var lastMotionTime: CFTimeInterval = 0
    private var lastRawHash: UInt64 = 0
    private var frameCount = 0
    private var consecutiveUnchangedCount = 0
    private var isComplete = false
    
    // Configuration
    private let requiredStableFrames = 4
    private let sampleSize: CGFloat = 70
    
    public init() {}
    
    public func startSampling(
        on view: UIView,
        completion: @escaping (Double) -> Void
    ) {
        self.targetView = view
        self.completion = completion
        self.isComplete = false
        self.frameCount = 0
        self.consecutiveUnchangedCount = 0
        self.lastRawHash = 0
        self.startTime = CACurrentMediaTime()
        self.lastMotionTime = self.startTime
        
        displayLink = CADisplayLink(
            target: self,
            selector: #selector(performCheck)
        )
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func performCheck() {
        guard let view = targetView, !isComplete else { return }
        
        self.frameCount += 1
        if self.frameCount % 5 != 0 { return }

        let rawHash = self.captureHash(from: view)
        
        // Zero-Frame early exit
        if rawHash == 0 && self.frameCount > 5 {
            self.finalize()
            return
        }
        
        if rawHash != self.lastRawHash {
            self.lastMotionTime = CACurrentMediaTime()
            self.lastRawHash = rawHash
            self.consecutiveUnchangedCount = 0
        } else if rawHash != 0 {
            self.consecutiveUnchangedCount += 1
            if self.consecutiveUnchangedCount >= self.requiredStableFrames {
                self.finalize()
            }
        }
    }
    
    private func captureHash(from view: UIView) -> UInt64 {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        let rect = CGRect(
            x: center.x - (sampleSize/2),
            y: center.y - (sampleSize/2),
            width: sampleSize,
            height: sampleSize
        )
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
    
        let image = UIGraphicsImageRenderer(
            size: rect.size,
            format: format
        ).image { context in
            self.sampleRenderStartTime = CACurrentMediaTime()
            context.cgContext.translateBy(x: -rect.origin.x, y: -rect.origin.y)
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }
        let durationMs = (CACurrentMediaTime() - sampleRenderStartTime) * 1000
        PSLog("⏱️ [PixelSampler] frame \(frameCount): \(String(format: "%.4f", durationMs))ms")
        return image.samplingHash()
    }
    
    private func finalize() {
        guard !isComplete else { return }
        isComplete = true
        
        displayLink?.invalidate()
        displayLink = nil
        
        let durationMs = (lastMotionTime - startTime) * 1000
        PSLog(
            "✅ [PixelSampler] Finished: sample size: \(sampleSize), duration \(String(format: "%.2f", durationMs))ms"
        )
        
        completion?(lastMotionTime)
    }
    
    private func findMetalLayer(in view: UIView) -> CAMetalLayer? {
        if let metal = view.layer as? CAMetalLayer { return metal }
        
        if let sublayers = view.layer.sublayers {
            for layer in sublayers {
                if let metal = layer as? CAMetalLayer { return metal }
            }
        }
        
        for subview in view.subviews {
            print(subview)
            if let found = findMetalLayer(in: subview) { return found }
        }
        return nil
        
    }
    
    private func measureHash(name: String, block: () -> UInt64) -> UInt64 {
        let startTime = CACurrentMediaTime()
        let result = block()
        let durationMs = (CACurrentMediaTime() - startTime) * 1000
        print(
            "⏱️ [PixelSampler] hash speed \(name): \(String(format: "%.4f", durationMs))ms"
        )
        return result
    }
}
