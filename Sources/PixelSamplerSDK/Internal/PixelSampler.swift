// Sources/PixelSamplerSDK/Internal/PixelSampler.swift
import UIKit

final class PixelSampler {
    private let targetView: UIView
    private let samplingPoints: [CGPoint]
    private let samplingSize: Int
    private let requiredUnchangedFrames: Int
    private var completion: ((CFTimeInterval) -> Void)?
    private var displayLink: CADisplayLink?
    
    private var frameHistory: [(hashes: [Int], timestamp: CFTimeInterval)] = []
    private var startTime: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var hasMeaningfulContent: Bool = false
    private var consecutiveUnchangedCount: Int = 0
    private var lastHashes: [Int] = []
    private var firstStableFrameTime: CFTimeInterval = 0
    private var stableSequenceStarted: Bool = false
    
    init(targetView: UIView,
         samplingPoints: [CGPoint],
         samplingSize: Int = 4,
         requiredUnchangedFrames: Int = 4) {
        self.targetView = targetView
        self.samplingPoints = samplingPoints
        self.samplingSize = samplingSize
        self.requiredUnchangedFrames = requiredUnchangedFrames
    }
    
    func startSampling(completion: @escaping (CFTimeInterval) -> Void) {
        self.completion = completion
        self.startTime = CACurrentMediaTime()
        self.frameHistory = []
        self.frameCount = 0
        self.hasMeaningfulContent = false
        self.consecutiveUnchangedCount = 0
        self.lastHashes = []
        self.firstStableFrameTime = 0
        self.stableSequenceStarted = false
        
        displayLink = CADisplayLink(target: self, selector: #selector(sampleFrame))
        displayLink?.preferredFramesPerSecond = 120
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func sampleFrame() {
        CATransaction.flush()
        
        let currentTime = CACurrentMediaTime()
        let currentHashes = samplingPoints.map { getRegionHash(at: $0, size: samplingSize) }
        frameCount += 1
        
        frameHistory.append((currentHashes, currentTime))
        if frameHistory.count > 100 {
            frameHistory.removeFirst()
        }
        
        if frameCount <= 10 {
            print("📊 [PIXEL_SAMPLER] Frame \(frameCount): Hashes = \(currentHashes)")
        }
        
        // IMPROVED: Check for meaningful content (non-transparent, non-background)
        let hasContent = currentHashes.contains { hash in
            let alpha = (hash >> 24) & 0xFF
            let r = (hash >> 16) & 0xFF
            let g = (hash >> 8) & 0xFF
            let b = hash & 0xFF
            
            // Ignore transparent (alpha < 50) and very dark/black pixels
            // Also ignore the greenish background (65280 = r=0, g=255, b=0, a=0)
            let isTransparent = alpha < 70
            let isBackground = (r < 10 && g < 10 && b < 10) || (r == 0 && g == 255 && b == 0)
            
            return !isTransparent && !isBackground && (r > 10 || g > 10 || b > 10)
        }
        
        // Start sequence on FIRST meaningful content
        if hasContent && !hasMeaningfulContent {
            print("🎯 [PIXEL_SAMPLER] First meaningful content at frame \(frameCount)")
            print("🎯 [PIXEL_SAMPLER] Hashes: \(currentHashes)")
            hasMeaningfulContent = true
            stableSequenceStarted = true
            firstStableFrameTime = currentTime
            consecutiveUnchangedCount = 1
            print("🔄 [PIXEL_SAMPLER] Stable sequence started at frame \(frameCount)")
        }
        else if hasMeaningfulContent {
            let isUnchanged = !lastHashes.isEmpty && currentHashes == lastHashes
            
            if isUnchanged && stableSequenceStarted {
                consecutiveUnchangedCount += 1
                print("🔄 [PIXEL_SAMPLER] Consecutive unchanged: \(consecutiveUnchangedCount)/\(requiredUnchangedFrames)")
                
                if consecutiveUnchangedCount >= requiredUnchangedFrames {
                    let elapsed = firstStableFrameTime - startTime
                    
                    print("✅ [PIXEL_SAMPLER] Render complete after \(frameCount) frames")
                    print("✅ [PIXEL_SAMPLER] First stable frame at frame \(frameCount - consecutiveUnchangedCount + 1)")
                    print("✅ [PIXEL_SAMPLER] First stable time: \(String(format: "%.3f", elapsed * 1000))ms")
                    
                    displayLink?.invalidate()
                    displayLink = nil
                    completion?(firstStableFrameTime)
                    return
                }
            } else if !isUnchanged {
                if stableSequenceStarted {
                    print("🔄 [PIXEL_SAMPLER] Stable sequence broken at frame \(frameCount)")
                    print("🔄 [PIXEL_SAMPLER] Previous hashes: \(lastHashes)")
                    print("🔄 [PIXEL_SAMPLER] Current hashes: \(currentHashes)")
                }
                stableSequenceStarted = false
                consecutiveUnchangedCount = 0
                firstStableFrameTime = 0
                
                // Check if this new frame is also meaningful and start new sequence
                if hasContent {
                    stableSequenceStarted = true
                    firstStableFrameTime = currentTime
                    consecutiveUnchangedCount = 1
                    print("🔄 [PIXEL_SAMPLER] New stable sequence started at frame \(frameCount)")
                }
            }
        }
        
        lastHashes = currentHashes
    }
    
    private func getRegionHash(at point: CGPoint, size: Int) -> Int {
        return autoreleasepool {
            guard size >= 1 else { return 0 }
            
            let regionSize = size
            let bytesPerPixel = 4
            let bytesPerRow = regionSize * bytesPerPixel
            let totalBytes = regionSize * regionSize * bytesPerPixel
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
            
            guard let context = CGContext(data: nil,
                                          width: regionSize,
                                          height: regionSize,
                                          bitsPerComponent: 8,
                                          bytesPerRow: bytesPerRow,
                                          space: colorSpace,
                                          bitmapInfo: bitmapInfo) else {
                return 0
            }
            
            // Sample the region around the point
            let halfSize = CGFloat(regionSize) / 2
            context.translateBy(x: -point.x + halfSize, y: -point.y + halfSize)
            targetView.layer.render(in: context)
            
            guard let data = context.data else { return 0 }
            let pixels = data.bindMemory(to: UInt8.self, capacity: totalBytes)
            
            // Calculate average color of the region
            var totalR = 0, totalG = 0, totalB = 0, totalA = 0
            let pixelCount = regionSize * regionSize
            
            for i in 0..<pixelCount {
                let offset = i * 4
                totalA += Int(pixels[offset])
                totalR += Int(pixels[offset + 1])
                totalG += Int(pixels[offset + 2])
                totalB += Int(pixels[offset + 3])
            }
            
            let avgR = totalR / pixelCount
            let avgG = totalG / pixelCount
            let avgB = totalB / pixelCount
            let avgA = totalA / pixelCount
            
            return (avgR << 24) | (avgG << 16) | (avgB << 8) | avgA
        }
    }
}
