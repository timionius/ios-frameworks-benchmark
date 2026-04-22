import UIKit

internal extension UIImage {
    func hashValue64() -> UInt64 {
        let startTime = CACurrentMediaTime()
        guard let cgImage = self.cgImage, let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else {
            return 0
        }
        let length = CFDataGetLength(data)
        let buffer = UnsafeBufferPointer(start: bytes, count: length)
        var hash: UInt64 = 5381
        for byte in buffer {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return hash
    }
    
    func samplingHash() -> UInt64 {
        guard let cgImage = self.cgImage, let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else {
            return 0
        }
        let length = CFDataGetLength(data)
        let buffer = UnsafeBufferPointer(start: bytes, count: length)
        
        var hash: UInt64 = 5381
        // Skip 4 bytes at a time (jumps over RGBA channels)
        for i in stride(from: 0, to: length, by: 4) {
            hash = ((hash << 5) &+ hash) &+ UInt64(buffer[i])
        }
        return hash
    }
    
    func fnv1aHash() -> UInt64 {
        guard let cgImage = self.cgImage, let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else {
            return 0
        }
        let length = CFDataGetLength(data)
        let buffer = UnsafeBufferPointer(start: bytes, count: length)
        
        var hash: UInt64 = 0xcbf29ce484222325 // FNV offset basis
        for byte in buffer {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3 // FNV prime
        }
        return hash
    }
    
    func adlerHash() -> UInt64 {
        guard let cgImage = self.cgImage, let data = cgImage.dataProvider?.data, let bytes = CFDataGetBytePtr(data) else {
            return 0
        }
        let length = CFDataGetLength(data)
        let buffer = UnsafeBufferPointer(start: bytes, count: length)
        
        var a: UInt64 = 1
        var b: UInt64 = 0
        
        for byte in buffer {
            a = (a + UInt64(byte)) % 65521
            b = (b + a) % 65521
        }
        return (b << 16) | a
    }
}
