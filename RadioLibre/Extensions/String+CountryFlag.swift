import Foundation

extension String {
    var flagEmoji: String {
        let base: UInt32 = 127397
        return unicodeScalars.compactMap { Unicode.Scalar(base + $0.value) }
            .map { String($0) }
            .joined()
    }
}
