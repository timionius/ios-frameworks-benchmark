// Examples/flutter_benchmark/ios/Runner/SceneDelegate.swift
import UIKit
import Flutter
import PixelSamplerSDK

class CustomSceneDelegate: NSObject, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {            
            self.window = windowScene.windows.first
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let window = self.window else { return }
        PixelSamplerSDK.windowIsReady(window)
    }
    
}
