import XCTest
@testable import PixelSamplerSDK

final class PixelSamplerSDKTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
#if DEBUG
        BenchmarkCoordinator.shared.reset()
#endif
    }
    
    func testSdkInitializtion() {
        PixelSamplerSDK.initialize()
        
        let results = PixelSamplerSDK.shared.getResults()
        XCTAssertNil(results)
    }
    
    func testMarkEvent() {
        PixelSamplerSDK.initialize()
        PixelSamplerSDK.shared.markEvent(.frameworkEntry)
        PixelSamplerSDK.shared.markEvent(.renderComplete)
        
        let results = PixelSamplerSDK.shared.getResults()
        XCTAssertNotNil(results?.details["FRAMEWORK_ENTRY"])
    }

}
