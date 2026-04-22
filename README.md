# 🚀 PixelSamplerSDK

PixelSamplerSDK is a high-precision performance monitoring tool for iOS. It captures the true visual app-start time by monitoring pixel-level stability in the view hierarchy. It supports Flutter and Compose Multiplatform (which uses Metal) and React Native (based on UIKit). SDK can also be used for SwiftUI application for a baseline benchmark.

## Key Features

- Low overhead to the application functionality.
- Uses CADisplayLink to hook into the frame pipeline for grabbing a sample area in the center of the screen.
- Tracks the sequence of frames until stability (no changes) in the scene
- Counts the first frame in the sequence as the finish of the animation on the screen

# 📦 Installation

Currently, the SDK is available as a local Swift package. Add it to your project via File > Add Packages... > Add Local.

# 🛠 Integration

## 1. Initialize the SDK

Initialize as early as possible (e.g., the first line of didFinishLaunchingWithOptions) to capture the absolute T=0.

```swift
// AppDelegate.swift
...
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        PixelSamplerSDK.initialize()
        return true
    }
...
```

## 2. Connect the Window

Pass your primary window in the SceneDelegate. The SDK will automatically locate the desired root UIView.

```swift
// SceneDelegate.swift
...
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
...
```

## 3. Retrieve Results

The SDK currently provides real-time benchmarking data directly to the Xcode Debug Console.

Note: The programmatic BenchmarkResults object and its export functions are currently in Alpha/Testing. For reliable production metrics, please use the Console Printout method below.

### Programmatic Access (Experimental):

If you wish to test the reporting structure, you can access it via the shared instance:

```swift
// Caution: API subject to change in future test cycles
if let results = PixelSamplerSDK.shared.getResults() {
    print("Reported Time: \(results.totalTimeMs)ms")
}
```

# 🔍 How it Works

1. T=0: Captured on initialize().
2. Hooking into frame pipeline: PixelSamplerSDK.windowIsReady(window). Since that time, SDK registers a callback on CADisplayLinke. 
3. Passive Snapshot: We take a 100x100 snapshot of the screen center using drawHierarchy on each 5th frame to minimize overhead on the app resources utilization.
4. Stability Logic: We compare the DJB2 hash of snapshots.
5. Benchmark Point: As soon as the hash stops changing for the duration of requiredStableFrames, we finalize the sampling job. The reported time is the timestamp of the first frame in that unchanged sequence, ensuring the benchmark represents the moment the animation ended. Worst-case inaccuracy ~67ms (4 × 16.67ms).

# 📈 Performance Benchmarks

To ensure the animation remains smooth, the hashing engine must execute in sub-millisecond time. Below are the average speeds recorded for a 100x100 (10,000 pixel) sampling area on a standard iOS device:

| Algorithm |  Avg. Execution Time | Efficiency |
|-----------|----------------------|-------------|
| DJB2 Mini (Default) | 0.051 ms | 🚀 Ultra Fast |
| DJB2 (Standard) | 0.185 ms | Good |
| FNV-1a | 0.241 ms | Moderate |
| Adler-32 | 0.527 ms | Slow |

## Why DJB2 Mini?
Minimal Overhead: At ~0.05ms, the overhead is virtually invisible to the Main Thread (which has a 16.6ms budget at 60fps).
High Sensitivity: Despite the speed, it effectively catches microscopic color shifts during animation easing phases.
Zero Jank: Even when sampling every single frame, there is no measurable drop in the application's frame rate.

# 🔧 Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.9+

# 📝 License

MIT License

Copyright (c) 2026 Dmitrii Nikishov

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
