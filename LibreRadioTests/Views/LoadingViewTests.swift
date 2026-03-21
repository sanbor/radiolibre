import XCTest
import SwiftUI
@testable import LibreRadio

final class LoadingViewTests: XCTestCase {

    @MainActor
    func testLoadingViewDefaultMessage() {
        let view = LoadingView()
        _ = view.body
        XCTAssertEqual(view.message, "Loading...")
    }

    @MainActor
    func testLoadingViewCustomMessage() {
        let view = LoadingView(message: "Loading stations...")
        _ = view.body
        XCTAssertEqual(view.message, "Loading stations...")
    }
}
