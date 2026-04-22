import XCTest
import Metal
@testable import PixelSamplerSDK

final class PixelSamplerEdgeTests: XCTestCase {
    
    // MARK: - Edge Case 1: Deep Nesting
    func testMetalLayerDeepNesting() {
        let sampler = PixelSampler()
        let root = UIView()
        var currentParent = root
        
        // Nest 10 levels deep
        for _ in 0..<10 {
            let child = UIView()
            currentParent.addSubview(child)
            currentParent = child
        }
        
        // Add a view with a Metal layer at the bottom
        let metalContainer = UIView()
        let metalLayer = CAMetalLayer()
        metalContainer.layer.addSublayer(metalLayer)
        currentParent.addSubview(metalContainer)
        
        // Use Mirror to test private method findMetalLayer
        let mirror = Mirror(reflecting: sampler)
        if let findMethod = mirror.descendant("findMetalLayer") as? (UIView) -> CAMetalLayer? {
            let foundLayer = findMethod(root)
            XCTAssertNotNil(foundLayer, "Should find Metal layer regardless of nesting depth")
            XCTAssertEqual(foundLayer, metalLayer)
        }
    }
    
    // MARK: - Edge Case 2: Fallback to UIKit
    @MainActor
    func testUIKitFallbackWhenMetalMissing() {
        let sampler = PixelSampler()
        let pureUIKitView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        let expectation = self.expectation(description: "Should complete using UIKit path")
        
        // Logic: Start sampling on a view that has NO Metal layer
        sampler.startSampling(on: pureUIKitView) { _ in
            expectation.fulfill()
        }
        
        // Trigger a change to ensure it doesn't get stuck
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            pureUIKitView.backgroundColor = .red
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Edge Case 3: Zero-Frame Early Exit
    @MainActor
    func testZeroFrameEarlyExit() {
        let sampler = PixelSampler()
        // Create a view that returns 0 hash (e.g. empty/hidden)
        let hiddenView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        hiddenView.isHidden = true
        
        let startTime = CACurrentMediaTime()
        
        let expectationDescription = "Should exit between 10th and 11th frame on zero hash"
        let expectation = self.expectation(description: expectationDescription)
        
        sampler.startSampling(on: hiddenView) { lastMotionTime in
            // Because it's hidden, captureHash should return 0
            // and trigger the 'frameCount > 5' should trigger after 10th frame
            let elapsedMs = (lastMotionTime - startTime) * 1000
            let frameCount = Int(elapsedMs / 16.67)
            
            XCTAssertGreaterThanOrEqual(10, frameCount, "LastMotionTime should be greater than time for 10 frames")
            XCTAssertLessThan(frameCount, 12, "LastMotionTime should happen earlier than 12 frame")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Unit Tests: Hashing Logic
    
    func testHashConsistency() {
        let size = CGSize(width: 100, height: 100)
        
        // Create two identical images
        let renderer = UIGraphicsImageRenderer(size: size)
        let image1 = renderer.image { $0.fill(CGRect(origin: .zero, size: size)) }
        let image2 = renderer.image { $0.fill(CGRect(origin: .zero, size: size)) }
        
        XCTAssertEqual(image1.hashValue64(), image2.hashValue64(), "Identical images must have same hash")
    }
    
    func testHashSensitivity() {
        let size = CGSize(width: 100, height: 100)
        
        // Create two slightly different images
        let renderer = UIGraphicsImageRenderer(size: size)
        let image1 = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        let image2 = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 50, y: 50, width: 1, height: 1)) // 1 pixel difference
        }
        
        XCTAssertNotEqual(image1.hashValue64(), image2.hashValue64(), "1-pixel change must change hash")
    }
    
}
