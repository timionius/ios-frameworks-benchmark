import Foundation

internal func PSLog(_ message: String) {
    #if PIXEL_SAMPLER_LOGGING
    print(message)
    #endif
}
