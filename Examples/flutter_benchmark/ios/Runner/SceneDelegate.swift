// Examples/flutter_benchmark/ios/Runner/SceneDelegate.swift
import UIKit
import Flutter
import PixelSamplerSDK

class CustomSceneDelegate: NSObject, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            // Initialize SDK - marks APP_START
            PixelSamplerSDK.initialize()
            
            self.window = windowScene.windows.first
            
            if let window = windowScene.windows.first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    PixelSamplerSDK.windowIsReady(window)
                }
            }
        }
    }
}
