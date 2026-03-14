import Foundation

// Source - https://stackoverflow.com/a/60413173
// Posted by habibiboss, modified by community. See post 'Timeline' for change history
// Retrieved 2026-03-14, License - CC BY-SA 4.0
internal func getFlag(from countryCode: String) -> String {
    countryCode
        .uppercased()
        .unicodeScalars
        .map({ 127397 + $0.value })
        .compactMap(UnicodeScalar.init)
        .map(String.init)
        .joined()
}
