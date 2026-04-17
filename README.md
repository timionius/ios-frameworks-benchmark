# 🚀 PixelSamplerSDK

PixelSamplerSDK is a high-precision performance monitoring tool for iOS. It captures the true visual app-start time by monitoring pixel-level stability in the view hierarchy. It is specifically optimized for Flutter (Metal/Impeller) and Native UIKit applications.

## Key Features

- Dual-Engine Support: Automatically detects Flutter (Metal) vs. Native UIKit and chooses the optimal synchronization path.
- Zero-Flicker Metal Sync: Synchronizes with the GPU via MTLCommandBuffer completion handlers to avoid the common "black screen" flicker caused by nextDrawable() calls.
- Last-Motion Benchmark: Calculates timing based on the actual last frame of an animation, providing millisecond accuracy for AnimatedContainer or Hero transitions.
- Thread Safety: Architected with @MainActor for compile-time safety

# 📦 Installation

Currently, the SDK is available as a local Swift package. Add it to your project via File > Add Packages... > Add Local.

# 🛠 Integration

## 1. Initialize the SDK

Initialize as early as possible (e.g., the first line of didFinishLaunchingWithOptions) to capture the absolute T=0.

```swift
// AppDelegate.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions ...) -> Bool {
    PixelSamplerSDK.initialize()
    return true
}
```

## 2. Connect the Window

Pass your primary window in the SceneDelegate. The SDK will automatically locate the FlutterView or root UIView.

```swift
// SceneDelegate.swift
func scene(_ scene: UIScene, willConnectTo session: ..., options ...) {
    guard let windowScene = (scene as? UIWindowScene) else { return }
    let window = UIWindow(windowScene: windowScene)
    self.window = window

    // Start sampling
    PixelSamplerSDK.windowIsReady(window)
}
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
2. GPU Handshake: On Flutter views, we commit an empty command buffer to the GPU. When it completes, we know the GPU has finished rendering Flutter's frames.
3. Passive Snapshot: We take a microscopic 100x100 snapshot of the screen center using drawHierarchy.
4. Stability Logic: We compare the DJB2 hash of each snapshot.
5. Benchmark Point: As soon as the hash stops changing for the duration of requiredStableFrames, we finalize the sampling job. The reported time is the timestamp of the first frame in that unchanged sequence, ensuring the benchmark represents the exact moment the animation ended.

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

MIT
