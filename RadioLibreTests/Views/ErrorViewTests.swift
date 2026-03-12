import XCTest
import SwiftUI
@testable import RadioLibre

final class ErrorViewTests: XCTestCase {

    @MainActor
    func testErrorViewRendersWithRetry() throws {
        let error = AppError.networkUnavailable
        var retryCalled = false
        let view = ErrorView(error: error) {
            retryCalled = true
        }

        // Verify the view can be created and its properties are correct
        XCTAssertEqual(view.error, .networkUnavailable)
        XCTAssertNotNil(view.onRetry)
        _ = retryCalled // suppress warning
    }

    @MainActor
    func testErrorViewRendersWithoutRetry() throws {
        let view = ErrorView(error: .streamURLInvalid)
        XCTAssertEqual(view.error, .streamURLInvalid)
        XCTAssertNil(view.onRetry)
    }

    @MainActor
    func testErrorViewRendersAllErrorTypes() {
        let errors: [AppError] = [
            .networkUnavailable,
            .serverDiscoveryFailed,
            .serverError(statusCode: 500),
            .decodingFailed(message: "test"),
            .streamURLInvalid,
            .audioSessionFailed(message: "test"),
            .playbackFailed(message: "test"),
            .noServersAvailable,
        ]

        for error in errors {
            let view = ErrorView(error: error) { }
            // Just verify body doesn't crash
            _ = view.body
        }
    }
}
