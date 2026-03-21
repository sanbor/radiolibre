import Foundation

enum StationSortOrder: String, CaseIterable {
    case byClicks
    case byName

    var label: String {
        switch self {
        case .byClicks: "Clicks"
        case .byName: "Name"
        }
    }

    var apiOrderParam: String {
        switch self {
        case .byClicks: "clickcount"
        case .byName: "name"
        }
    }

    var apiReverse: Bool {
        switch self {
        case .byClicks: true
        case .byName: false
        }
    }
}
