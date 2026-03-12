import XCTest
@testable import RadioLibre

final class AppErrorTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertEqual(AppError.networkUnavailable.errorDescription, "No internet connection")
        XCTAssertEqual(AppError.serverDiscoveryFailed.errorDescription, "Could not discover radio servers")
        XCTAssertEqual(AppError.serverError(statusCode: 500).errorDescription, "Server error (500)")
        XCTAssertEqual(AppError.serverError(statusCode: 404).errorDescription, "Server error (404)")
        XCTAssertEqual(AppError.decodingFailed(message: "bad json").errorDescription, "Failed to read server response")
        XCTAssertEqual(AppError.streamURLInvalid.errorDescription, "Invalid stream URL")
        XCTAssertEqual(AppError.audioSessionFailed(message: "err").errorDescription, "Audio session error")
        XCTAssertEqual(AppError.playbackFailed(message: "err").errorDescription, "Playback failed")
        XCTAssertEqual(AppError.noServersAvailable.errorDescription, "No servers available")
    }

    func testRecoverySuggestions() {
        XCTAssertNotNil(AppError.networkUnavailable.recoverySuggestion)
        XCTAssertNotNil(AppError.serverDiscoveryFailed.recoverySuggestion)
        XCTAssertNotNil(AppError.serverError(statusCode: 500).recoverySuggestion)
        XCTAssertNotNil(AppError.decodingFailed(message: "test").recoverySuggestion)
        XCTAssertNotNil(AppError.streamURLInvalid.recoverySuggestion)
        XCTAssertNotNil(AppError.audioSessionFailed(message: "test").recoverySuggestion)
        XCTAssertNotNil(AppError.playbackFailed(message: "test").recoverySuggestion)
        XCTAssertNotNil(AppError.noServersAvailable.recoverySuggestion)
    }

    func testEquality() {
        XCTAssertEqual(AppError.networkUnavailable, AppError.networkUnavailable)
        XCTAssertEqual(AppError.serverDiscoveryFailed, AppError.serverDiscoveryFailed)
        XCTAssertEqual(AppError.streamURLInvalid, AppError.streamURLInvalid)
        XCTAssertEqual(AppError.noServersAvailable, AppError.noServersAvailable)
        XCTAssertEqual(AppError.serverError(statusCode: 500), AppError.serverError(statusCode: 500))
        XCTAssertEqual(AppError.decodingFailed(message: "a"), AppError.decodingFailed(message: "a"))
        XCTAssertEqual(AppError.audioSessionFailed(message: "a"), AppError.audioSessionFailed(message: "a"))
        XCTAssertEqual(AppError.playbackFailed(message: "a"), AppError.playbackFailed(message: "a"))
    }

    func testInequality() {
        XCTAssertNotEqual(AppError.networkUnavailable, AppError.serverDiscoveryFailed)
        XCTAssertNotEqual(AppError.serverError(statusCode: 500), AppError.serverError(statusCode: 404))
        XCTAssertNotEqual(AppError.decodingFailed(message: "a"), AppError.decodingFailed(message: "b"))
        XCTAssertNotEqual(AppError.networkUnavailable, AppError.noServersAvailable)
    }
}
