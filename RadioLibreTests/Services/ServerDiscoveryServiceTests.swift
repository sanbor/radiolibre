import XCTest
@testable import RadioLibre

final class ServerDiscoveryServiceTests: XCTestCase {

    private var testDefaults: UserDefaults!

    override func setUp() {
        testDefaults = UserDefaults(suiteName: "ServerDiscoveryTests")!
        testDefaults.removePersistentDomain(forName: "ServerDiscoveryTests")
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "ServerDiscoveryTests")
    }

    // MARK: - Default State

    func testDefaultBaseURL() async {
        let service = makeService(resolver: { [] })
        let url = await service.currentBaseURL
        XCTAssertEqual(url.absoluteString, "https://de1.api.radio-browser.info")
    }

    // MARK: - setServers

    func testSetServersUpdatesBaseURL() async {
        let service = makeService(resolver: { [] })
        await service.setServers(["test1.api.radio-browser.info"])

        let url = await service.currentBaseURL
        XCTAssertEqual(url.absoluteString, "https://test1.api.radio-browser.info")
    }

    // MARK: - Rotation

    func testRotateServerCyclesThroughAll() async {
        let service = makeService(resolver: { [] })
        await service.setServers(["s1.test", "s2.test", "s3.test"])

        let url1 = await service.currentBaseURL
        XCTAssertEqual(url1.absoluteString, "https://s1.test")

        await service.rotateServer()
        let url2 = await service.currentBaseURL
        XCTAssertEqual(url2.absoluteString, "https://s2.test")

        await service.rotateServer()
        let url3 = await service.currentBaseURL
        XCTAssertEqual(url3.absoluteString, "https://s3.test")

        await service.rotateServer()
        let url4 = await service.currentBaseURL
        XCTAssertEqual(url4.absoluteString, "https://s1.test")
    }

    func testRotateSingleServerNoOp() async {
        let service = makeService(resolver: { [] })
        await service.setServers(["only.test"])

        await service.rotateServer()
        let url = await service.currentBaseURL
        XCTAssertEqual(url.absoluteString, "https://only.test")
    }

    func testRotateEmptyServersNoOp() async {
        let service = makeService(resolver: { [] })
        await service.rotateServer()
        let url = await service.currentBaseURL
        XCTAssertEqual(url.absoluteString, "https://de1.api.radio-browser.info")
    }

    // MARK: - resolveIfNeeded

    func testResolveIfNeededSkipsWhenFresh() async {
        var resolveCount = 0
        let service = makeService(resolver: {
            resolveCount += 1
            return ["resolved.test"]
        })
        await service.setServers(["cached.test"])

        await service.resolveIfNeeded()

        XCTAssertEqual(resolveCount, 0)
        let url = await service.currentBaseURL
        XCTAssertEqual(url.absoluteString, "https://cached.test")
    }

    func testResolveIfNeededCallsResolverWhenNoServers() async {
        var resolveCount = 0
        let service = makeService(resolver: {
            resolveCount += 1
            return ["new-server.test"]
        })

        await service.resolveIfNeeded()

        XCTAssertEqual(resolveCount, 1)
        // Servers are shuffled so we just check it's set
        let url = await service.currentBaseURL
        XCTAssertTrue(url.absoluteString.contains("new-server.test"))
    }

    func testResolveIfNeededHandlesDNSFailure() async {
        let service = makeService(resolver: {
            throw AppError.serverDiscoveryFailed
        })

        // Should not crash
        await service.resolveIfNeeded()

        // Falls back to default
        let url = await service.currentBaseURL
        XCTAssertEqual(url.absoluteString, "https://de1.api.radio-browser.info")
    }

    func testResolveIfNeededIgnoresEmptyResult() async {
        let service = makeService(resolver: { [] })

        await service.resolveIfNeeded()

        let url = await service.currentBaseURL
        XCTAssertEqual(url.absoluteString, "https://de1.api.radio-browser.info")
    }

    func testResolveIfNeededFallsToCacheAfterClearAndDNSFailure() async {
        var callCount = 0
        let service = makeService(resolver: {
            callCount += 1
            if callCount == 1 {
                return ["first.test"]
            }
            throw AppError.serverDiscoveryFailed
        })

        // First resolve succeeds and caches to UserDefaults
        await service.resolveIfNeeded()
        let url1 = await service.currentBaseURL
        XCTAssertTrue(url1.absoluteString.contains("first.test"))

        // Clear in-memory state but cache remains in UserDefaults
        await service.clearState()
        await service.resolveIfNeeded()

        // Should load from UserDefaults cache even though DNS failed
        let url2 = await service.currentBaseURL
        XCTAssertTrue(url2.absoluteString.contains("first.test"))
    }

    func testDNSFailureWithNoCacheFallsToDefault() async {
        let service = makeService(resolver: {
            throw AppError.serverDiscoveryFailed
        })

        await service.resolveIfNeeded()

        let url = await service.currentBaseURL
        XCTAssertEqual(url.absoluteString, "https://de1.api.radio-browser.info")
    }

    // MARK: - UserDefaults Cache

    func testSavesAndLoadsFromCache() async {
        let service1 = makeService(resolver: {
            return ["cached-server.test"]
        })
        await service1.resolveIfNeeded()

        // Create a new service with the same defaults — should load from cache
        var resolveCount = 0
        let service2 = makeService(resolver: {
            resolveCount += 1
            return ["should-not-be-used.test"]
        })
        await service2.resolveIfNeeded()

        XCTAssertEqual(resolveCount, 0)
        let url = await service2.currentBaseURL
        XCTAssertTrue(url.absoluteString.contains("cached-server.test"))
    }

    func testExpiredCacheTriggersResolve() async {
        // Manually set expired cache
        testDefaults.set(["old-server.test"], forKey: "radio_browser_servers")
        testDefaults.set(Date.distantPast, forKey: "radio_browser_servers_ts")

        var resolveCount = 0
        let service = makeService(resolver: {
            resolveCount += 1
            return ["fresh-server.test"]
        })
        await service.resolveIfNeeded()

        XCTAssertEqual(resolveCount, 1)
        let url = await service.currentBaseURL
        XCTAssertTrue(url.absoluteString.contains("fresh-server.test"))
    }

    func testEmptyCacheTriggersResolve() async {
        testDefaults.set([String](), forKey: "radio_browser_servers")
        testDefaults.set(Date(), forKey: "radio_browser_servers_ts")

        var resolveCount = 0
        let service = makeService(resolver: {
            resolveCount += 1
            return ["new.test"]
        })
        await service.resolveIfNeeded()

        XCTAssertEqual(resolveCount, 1)
    }

    func testMissingTimestampTriggersResolve() async {
        testDefaults.set(["server.test"], forKey: "radio_browser_servers")
        // No timestamp set

        var resolveCount = 0
        let service = makeService(resolver: {
            resolveCount += 1
            return ["resolved.test"]
        })
        await service.resolveIfNeeded()

        XCTAssertEqual(resolveCount, 1)
    }

    // MARK: - clearState

    func testClearState() async {
        let service = makeService(resolver: { ["server.test"] })
        await service.setServers(["existing.test"])

        await service.clearState()

        let url = await service.currentBaseURL
        XCTAssertEqual(url.absoluteString, "https://de1.api.radio-browser.info")
    }

    // MARK: - Helpers

    private func makeService(
        resolver: @escaping @Sendable () async throws -> [String]
    ) -> ServerDiscoveryService {
        ServerDiscoveryService(defaults: testDefaults, dnsResolver: resolver)
    }
}
