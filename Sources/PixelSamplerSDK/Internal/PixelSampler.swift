import UIKit
import Metal

public class PixelSampler {
    
    private weak var targetView: UIView?
    private var displayLink: CADisplayLink?
    private var commandQueue: MTLCommandQueue?
    
    // Callbacks & State
    private var completion: ((Double) -> Void)?
    private var startTime: CFTimeInterval = 0
    private var lastMotionTime: CFTimeInterval = 0
    private var lastRawHash: UInt64 = 0
    private var frameCount = 0
    private var consecutiveUnchangedCount = 0
    private var isComplete = false
    
    // Configuration
    private let requiredStableFrames = 10
    private let sampleSize: CGFloat = 100
    
    public init() {}
    
    public func startSampling(on view: UIView, completion: @escaping (Double) -> Void) {
        self.targetView = view
        self.completion = completion
        self.isComplete = false
        self.frameCount = 0
        self.consecutiveUnchangedCount = 0
        self.lastRawHash = 0
        self.startTime = CACurrentMediaTime()
        self.lastMotionTime = self.startTime
        
        let viewType = String(describing: type(of: view))
        if viewType.contains("FlutterView"), let metalLayer = findMetalLayer(in: view) {
            self.commandQueue = metalLayer.device?.makeCommandQueue()
            PSLog("\n✅ [PixelSampler] Flutter/Metal detected - GPU Sync enabled")
        } else {
            self.commandQueue = nil
            PSLog("\n✅ [PixelSampler] Standard UIKit path enabled")
        }

        displayLink = CADisplayLink(target: self, selector: #selector(handleTick))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func handleTick() {
        guard !isComplete else { return }
        
        if let queue = commandQueue {
            let commandBuffer = queue.makeCommandBuffer()
            commandBuffer?.addCompletedHandler { [weak self] _ in
                DispatchQueue.main.async { self?.performCheck() }
            }
            commandBuffer?.commit()
        } else {
            performCheck()
        }
    }
    
    private func performCheck() {
        guard let view = targetView, !isComplete else { return }
        
        let rawHash = captureHash(from: view)
        
        // Zero-Frame early exit
        if rawHash == 0 && frameCount > 5 {
            finalize()
            return
        }
        
        if rawHash != lastRawHash {
            lastMotionTime = CACurrentMediaTime()
            lastRawHash = rawHash
            consecutiveUnchangedCount = 0
        } else if rawHash != 0 {
            consecutiveUnchangedCount += 1
            if consecutiveUnchangedCount >= requiredStableFrames {
                finalize()
            }
        }
        frameCount += 1
    }
    
    private func captureHash(from view: UIView) -> UInt64 {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        let rect = CGRect(x: center.x - (sampleSize/2), y: center.y - (sampleSize/2), width: sampleSize, height: sampleSize)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        
        let image = UIGraphicsImageRenderer(size: rect.size, format: format).image { context in
            context.cgContext.translateBy(x: -rect.origin.x, y: -rect.origin.y)
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
        }
        return measureHash(name: "DJB2 Mini") { image.samplingHash() }
    }
    
    private func finalize() {
        guard !isComplete else { return }
        isComplete = true
        
        displayLink?.invalidate()
        displayLink = nil
        
        let durationMs = (lastMotionTime - startTime) * 1000
        PSLog("✅ [PixelSampler] Finished: sample size: \(sampleSize), duration \(String(format: "%.2f", durationMs))ms")
        
        completion?(lastMotionTime)
    }
    
    private func findMetalLayer(in view: UIView) -> CAMetalLayer? {
        if let metal = view.layer as? CAMetalLayer { return metal }
        return view.subviews.compactMap { findMetalLayer(in: $0) }.first
    }
    
    private func measureHash(name: String, block: () -> UInt64) -> UInt64 {
        let startTime = CACurrentMediaTime()
        let result = block()
        let durationMs = (CACurrentMediaTime() - startTime) * 1000
        print("⏱️ [PixelSampler] hash speed \(name): \(String(format: "%.4f", durationMs))ms")
        return result
    }
}

fileprivate extension UIImage {
    func hashValue64() -> UInt64 {
        let startTime = CACurrentMediaTime()
        guard let cgImage = self.cgImage, let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return 0 }
        let length = CFDataGetLength(data)
        let buffer = UnsafeBufferPointer(start: bytes, count: length)
        var hash: UInt64 = 5381
        for byte in buffer {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return hash
    }
    
    func samplingHash() -> UInt64 {
        guard let cgImage = self.cgImage, let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return 0 }
        let length = CFDataGetLength(data)
        let buffer = UnsafeBufferPointer(start: bytes, count: length)
        
        var hash: UInt64 = 5381
        // Skip 4 bytes at a time (jumps over RGBA channels)
        for i in stride(from: 0, to: length, by: 4) {
            hash = ((hash << 5) &+ hash) &+ UInt64(buffer[i])
        }
        return hash
    }

    func fnv1aHash() -> UInt64 {
        guard let cgImage = self.cgImage, let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return 0 }
        let length = CFDataGetLength(data)
        let buffer = UnsafeBufferPointer(start: bytes, count: length)
        
        var hash: UInt64 = 0xcbf29ce484222325 // FNV offset basis
        for byte in buffer {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3 // FNV prime
        }
        return hash
    }

    func adlerHash() -> UInt64 {
        guard let cgImage = self.cgImage, let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else { return 0 }
        let length = CFDataGetLength(data)
        let buffer = UnsafeBufferPointer(start: bytes, count: length)
        
        var a: UInt64 = 1
        var b: UInt64 = 0
        
        for byte in buffer {
            a = (a + UInt64(byte)) % 65521
            b = (b + a) % 65521
        }
        return (b << 16) | a
    }

}
