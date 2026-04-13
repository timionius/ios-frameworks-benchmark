# iOS Frameworks Benchmark

Cross-platform benchmarking SDK for measuring render performance of iOS UI frameworks using pixel sampling and stability detection.

## 🎯 Purpose

Compare the **actual render performance** of different iOS UI frameworks:
- SwiftUI
- UIKit  
- React Native
- Flutter
- Compose Multiplatform

## 📊 What It Measures

| Metric | Description |
|--------|-------------|
| **App Start → Framework Entry** | Time from launch to framework initialization |
| **Framework Entry → Layout Start** | Time to begin layout calculation |
| **Layout Duration** | Time spent calculating layout |
| **Layout → Render Complete** | Time from layout to fully rendered images |
| **Total Render Time** | Complete time from app launch to stable render |

## 🔬 How It Works

1. **Swizzling Injection** - Captures earliest possible window creation
2. **Pixel Sampling** - Monitors specific screen regions (image centers)
3. **Stability Detection** - Waits for 4 consecutive unchanged frames
4. **CALayer.render** - Accurate content capture without Metal overhead

## 🚀 Quick Start

### SwiftUI
```swift
// AppDelegate
PixelSamplerSDK.initialize()

// ContentView
.onAppear {
    PixelSamplerSDK.shared.startBenchmark()
}
```

### UIKit
```swift
// AppDelegate
PixelSamplerSDK.initialize()

// ViewController
override func viewDidAppear(_ animated: Bool) {
    PixelSamplerSDK.shared.startBenchmark()
    PixelSamplerSDK.shared.markLayoutStarted()
    // after layout
    PixelSamplerSDK.shared.markLayoutFinished()
}
```

### React Native

import { Benchmark } from 'ios-frameworks-benchmark';
```js
Benchmark.initialize();
Benchmark.startBenchmark(3);
const timeMs = await Benchmark.waitForComplete();
```

## 📈 Example Results

══════════════════════════════════════════════════════════════════
📊 RENDER BENCHMARK RESULTS
══════════════════════════════════════════════════════════════════

  App Start → Framework Entry:        45.234ms
  Framework Entry → Layout Start:      0.889ms
  Layout Duration:                     0.002ms
  Layout → Render Complete:           32.331ms
  ─────────────────────────────────────────────────────
  TOTAL TO RENDER COMPLETE:           78.456ms

══════════════════════════════════════════════════════════════════
  ✅ Render detected by pixel stability
  📍 First unchanged frame in series of 4
══════════════════════════════════════════════════════════════════

## 🏗️ Architecture
```text
ios-frameworks-benchmark/
├── PixelSamplerSDK/     # Core benchmarking engine
├── Examples/            # Framework integration examples
│   ├── SwiftUI/
│   ├── UIKit/
│   ├── ReactNative/
│   ├── Flutter/
│   └── Compose/
├── Tests/               # Unit tests
├── Scripts/             # Benchmark automation
└── Results/             # Performance data
```

## 🔧 Requirements

iOS 16.0+
Xcode 14.0+
Swift 5.9+

## 📝 License

MIT