// Sources/PixelSamplerSDK/Internal/FlutterMetalSampler.swift
import UIKit
import Metal

class FlutterMetalSampler {
    
    private var metalLayer: CAMetalLayer?
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var consecutiveUnchangedCount = 0
    private var lastRawHash: UInt64 = 0
    private var isComplete = false
    private let requiredStableFrames = 4
    private var completion: ((UInt64) -> Void)?
    
    func startSampling(on view: UIView, completion: @escaping (UInt64) -> Void) {
        self.completion = completion
        
        guard let metalLayer = findMetalLayer(in: view) else {
            print("⚠️ No Metal layer found")
            return
        }
        
        self.metalLayer = metalLayer
        waitForMetalLayerReady()
    }
    
    private func findMetalLayer(in view: UIView) -> CAMetalLayer? {
        if let flutterView = findFlutterView(in: view),
           let metalLayer = flutterView.layer as? CAMetalLayer {
            return metalLayer
        }
        return nil
    }
    
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
    
    private func waitForMetalLayerReady() {
        guard let metalLayer = metalLayer else { return }
        
        if metalLayer.drawableSize.width > 0 && metalLayer.drawableSize.height > 0 {
            print("✅ Metal layer ready")
            startFrameCapture()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.waitForMetalLayerReady()
            }
        }
    }
    
    private func startFrameCapture() {
        displayLink = CADisplayLink(target: self, selector: #selector(captureFrame))
        displayLink?.add(to: .main, forMode: .common)
        print("📍 Metal frame capture started")
    }
    
    @objc private func captureFrame() {
        guard !isComplete, let metalLayer = metalLayer else { return }
        
        frameCount += 1
        
        let centerX = metalLayer.drawableSize.width / 2
        let centerY = metalLayer.drawableSize.height / 2
        let point = CGPoint(x: centerX, y: centerY)
        
        let rawHash = captureRawHash(from: metalLayer, at: point)
        
        if frameCount <= 10 {
            print("📊 Frame \(frameCount): Hash = \(rawHash)")
        }
        
        let hasContent = rawHash != 0
        
        if hasContent {
            if rawHash == lastRawHash {
                consecutiveUnchangedCount += 1
                print("🔄 Stable frame \(consecutiveUnchangedCount)/\(requiredStableFrames)")
                
                if consecutiveUnchangedCount >= requiredStableFrames {
                    print("\n✅ Render complete after \(frameCount) frames")
                    isComplete = true
                    displayLink?.invalidate()
                    completion?(rawHash)
                }
            } else {
                if consecutiveUnchangedCount > 0 {
                    print("🔄 Content changed at frame \(frameCount)")
                }
                consecutiveUnchangedCount = 1
                lastRawHash = rawHash
            }
        }
    }
    
    private func captureRawHash(from metalLayer: CAMetalLayer, at point: CGPoint) -> UInt64 {
        guard let drawable = metalLayer.nextDrawable() else { return 0 }
        
        let texture = drawable.texture
        let x = Int(point.x)
        let y = Int(point.y)
        
        var pixelData1 = [UInt16](repeating: 0, count: 4)
        texture.getBytes(&pixelData1,
                         bytesPerRow: 8,
                         from: MTLRegionMake2D(x, y, 1, 1),
                         mipmapLevel: 0)
        
        var pixelData2 = [UInt16](repeating: 0, count: 4)
        texture.getBytes(&pixelData2,
                         bytesPerRow: 8,
                         from: MTLRegionMake2D(x, y, 1, 1),
                         mipmapLevel: 0)
        
        let pixelData = (pixelData1 == pixelData2) ? pixelData1 : pixelData2
        
        return (UInt64(pixelData[0]) << 48) |
               (UInt64(pixelData[1]) << 32) |
               (UInt64(pixelData[2]) << 16) |
               UInt64(pixelData[3])
    }
}
