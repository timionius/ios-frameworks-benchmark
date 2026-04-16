import XCTest
@testable import PixelSamplerSDK

final class PixelSamplerSDKTests: XCTestCase {

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

    // MARK: - Unit Tests: Timing Logic
    
    func testCoordinatorAppStartLock() {
        let coordinator = BenchmarkCoordinator.shared
        coordinator.markAppStart()
        
        let firstStart = coordinator.getResults()?.timeForEvent(.applicationStart) ?? -1
        
        // Try to initialize again
        Thread.sleep(forTimeInterval: 0.1)
        coordinator.markAppStart()
        
        let secondStart = coordinator.getResults()?.timeForEvent(.applicationStart) ?? -1
        
        XCTAssertEqual(firstStart, secondStart, "markAppStart should be idempotent (only set once)")
    }

    // MARK: - Integration Tests: Mock Animation
    
    @MainActor
    func testSamplerDetectsAnimationEnd() {
        let sampler = PixelSampler()
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let animatedView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        animatedView.backgroundColor = .red
        containerView.addSubview(animatedView)
        
        let expectation = self.expectation(description: "Sampler detects end of 1s animation")
        
        // Start sampling
        sampler.startSampling(on: containerView) { durationMs in
            // We expect roughly 1000ms.
            // We use a wide range to account for CI runner lag.
            XCTAssertTrue(durationMs >= 900 && durationMs <= 1500, "Duration should be ~1000ms, got \(durationMs)ms")
            expectation.fulfill()
        }
        
        // Trigger a 1-second animation
        UIView.animate(withDuration: 1.0, animations: {
            animatedView.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
            animatedView.backgroundColor = .blue
        })
        
        waitForExpectations(timeout: 5.0)
    }
}
