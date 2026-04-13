import UIKit
import PixelSamplerSDK

class CustomSceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // This is the hook you requested
        if let windowScene = scene as? UIWindowScene {
            // You can also access windowScene.windows here if needed
            PixelSamplerSDK.initialize()
            if let window = windowScene.windows.first {
                PixelSamplerSDK.windowIsReady(window)
            }
        }
    }
}
