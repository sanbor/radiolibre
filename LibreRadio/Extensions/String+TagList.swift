import Foundation

extension String {
    /// Splits a comma-separated tag string into a trimmed, non-empty array.
    var asTagList: [String] {
        guard !isEmpty else { return [] }
        return split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}
