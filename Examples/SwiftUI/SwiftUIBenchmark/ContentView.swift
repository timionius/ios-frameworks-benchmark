import SwiftUI
import PixelSamplerSDK

struct ContentView: View {
    let imageNames = ["photo.fill", "camera.fill", "star.fill"]
    private static var hasMarkedFrameworkEntry = false
    
    // Animation states
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5
    
    init() {
        if !Self.hasMarkedFrameworkEntry {
            Self.hasMarkedFrameworkEntry = true
            PixelSamplerSDK.shared.markEvent(.frameworkEntry)
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 25) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: imageNames[index])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 110, height: 110)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .opacity(opacity)
                        .scaleEffect(scale)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 1)) {
                opacity = 1
                scale = 1
            }
        }
    }
}
