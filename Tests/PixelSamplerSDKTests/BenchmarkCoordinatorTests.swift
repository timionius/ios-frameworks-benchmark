import XCTest
@testable import PixelSamplerSDK

final class BenchmarkCoordinatorTests: XCTestCase {
    
    var coordinator: BenchmarkCoordinator!
    
    override func setUp() {
        super.setUp()
        // Accessing the shared instance.
        // Note: In a real test, you might want a fresh instance per test,
        // but since it's a singleton, we ensure it's reset where possible.
        coordinator = BenchmarkCoordinator.shared
    }

    override func tearDown() {
        // Clean up state so the next test starts fresh
        BenchmarkCoordinator.shared.reset()
        super.tearDown()
    }
    
    // MARK: - Test 1: App Start Idempotency
    func testMarkAppStartOnlySetsOnce() {
        coordinator.markAppStart()
        let firstStart = coordinator.getResults()?.timeForEvent(.applicationStart) ?? -1
        
        // Wait a bit and try to mark start again
        Thread.sleep(forTimeInterval: 0.05)
        coordinator.markAppStart()
        
        let secondStart = coordinator.getResults()?.timeForEvent(.applicationStart) ?? -1
        
        XCTAssertEqual(firstStart, secondStart, "Subsequent calls to markAppStart should not overwrite T=0")
        XCTAssertEqual(firstStart, 0.0, "Application start event must always be 0.0ms")
    }

    // MARK: - Test 2: Relative Timing Accuracy
    func testMarkEventCalculatesCorrectRelativeTime() {
        coordinator.markAppStart()
        
        let sleepDuration: TimeInterval = 0.2 // 200ms
        Thread.sleep(forTimeInterval: sleepDuration)
        
        coordinator.markEvent(.frameworkEntry)
        
        guard let results = coordinator.getResults(),
              let entryTime = results.timeForEvent(.frameworkEntry) else {
            XCTFail("Results or event missing")
            return
        }
        
        // We expect ~200ms with a small margin for execution time
        XCTAssertTrue(entryTime >= 190 && entryTime <= 250, "Event timing should reflect the 200ms delay, got \(entryTime)ms")
    }

    // MARK: - Test 3: Results Availability
    func testGetResultsReturnsNilUntilRenderComplete() {
        coordinator.markAppStart()
        coordinator.markEvent(.frameworkEntry)
        
        // At this point, sampling hasn't finished
        XCTAssertNil(coordinator.getResults(), "Results should be nil until .renderComplete is marked")
    }

    // MARK: - Test 4: Final Report Consistency
    @MainActor
    func testFinalReportStructure() {
        coordinator.markAppStart()
        coordinator.markEvent(.frameworkEntry)
        
        // Manually simulate the sampler finishing
        let mockEndTime = CACurrentMediaTime() + 1.0 // 1 second later
        
        // Use a mock duration for the renderComplete event
        coordinator.markEvent(.renderComplete)
        
        guard let results = coordinator.getResults() else {
            XCTFail("Final results missing")
            return
        }
        
        XCTAssertNotNil(results.details["APP_START"])
        XCTAssertNotNil(results.details["FRAMEWORK_ENTRY"])
        XCTAssertNotNil(results.details["total_time"])
        XCTAssertEqual(results.totalTimeMs, results.details["total_time"])
    }
}
