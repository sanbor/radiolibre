import XCTest
@testable import LibreRadio

final class ImageCacheServiceTests: XCTestCase {
    private var sut: ImageCacheService!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let session = TestFixtures.makeMockSession()
        sut = ImageCacheService(session: session, cacheDirectory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        MockURLProtocol.requestHandler = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeTestPNGData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.pngData { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    private func setMockImageResponse(url: URL, data: Data, statusCode: Int = 200) {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: statusCode,
                httpVersion: nil, headerFields: nil
            )!
            return (response, data)
        }
    }

    // MARK: - Tests

    func testNetworkLoadReturnsImage() async {
        let url = URL(string: "https://example.com/icon.png")!
        let pngData = makeTestPNGData()
        setMockImageResponse(url: url, data: pngData)

        let image = await sut.image(for: url)
        XCTAssertNotNil(image)
    }

    func testMemoryCacheHit() async {
        let url = URL(string: "https://example.com/icon.png")!
        let pngData = makeTestPNGData()
        setMockImageResponse(url: url, data: pngData)

        // First load populates cache
        _ = await sut.image(for: url)

        // Track whether network was hit again
        var networkHit = false
        MockURLProtocol.requestHandler = { request in
            networkHit = true
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            return (response, pngData)
        }

        // Second load should be from memory
        let image = await sut.image(for: url)
        XCTAssertNotNil(image)
        XCTAssertFalse(networkHit)
    }

    func testDiskCacheHit() async {
        let url = URL(string: "https://example.com/disk-icon.png")!
        let pngData = makeTestPNGData()
        setMockImageResponse(url: url, data: pngData)

        // First load populates both caches
        _ = await sut.image(for: url)

        // Create new instance with same disk dir (fresh memory cache)
        let session2 = TestFixtures.makeMockSession()
        var networkHit = false
        MockURLProtocol.requestHandler = { request in
            networkHit = true
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200,
                httpVersion: nil, headerFields: nil
            )!
            return (response, pngData)
        }

        let sut2 = ImageCacheService(session: session2, cacheDirectory: tempDir)
        let image = await sut2.image(for: url)
        XCTAssertNotNil(image)
        XCTAssertFalse(networkHit)
    }

    func testNilOnNetworkError() async {
        let url = URL(string: "https://example.com/fail.png")!
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let image = await sut.image(for: url)
        XCTAssertNil(image)
    }

    func testNilOnInvalidData() async {
        let url = URL(string: "https://example.com/bad.png")!
        setMockImageResponse(url: url, data: Data("not an image".utf8))

        let image = await sut.image(for: url)
        XCTAssertNil(image)
    }

    func testDifferentURLsDifferentFiles() async {
        let url1 = URL(string: "https://example.com/a.png")!
        let url2 = URL(string: "https://example.com/b.png")!
        let pngData = makeTestPNGData()
        setMockImageResponse(url: url1, data: pngData)

        _ = await sut.image(for: url1)
        _ = await sut.image(for: url2)

        let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(files?.count, 2)
    }

    func testSHA256Consistency() async {
        let url = URL(string: "https://example.com/consistent.png")!
        let pngData = makeTestPNGData()
        setMockImageResponse(url: url, data: pngData)

        _ = await sut.image(for: url)
        _ = await sut.image(for: url)

        // Should still be just one file since same URL
        let files = try? FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(files?.count, 1)
    }

    func testSynchronousCachedImageAfterAsyncLoad() async {
        let url = URL(string: "https://example.com/sync.png")!
        let pngData = makeTestPNGData()
        setMockImageResponse(url: url, data: pngData)

        // Before load - should be nil
        let before = sut.cachedImage(for: url)
        XCTAssertNil(before)

        // After load - should work synchronously
        _ = await sut.image(for: url)
        let after = sut.cachedImage(for: url)
        XCTAssertNotNil(after)
    }

    func testNilOnNon200StatusCode() async {
        let url = URL(string: "https://example.com/404.png")!
        let pngData = makeTestPNGData()
        setMockImageResponse(url: url, data: pngData, statusCode: 404)

        let image = await sut.image(for: url)
        XCTAssertNil(image)
    }

    // MARK: - Pre-warm Memory Cache

    func testPreWarmPromotesDiskToMemory() async {
        let url = URL(string: "https://example.com/warm.png")!
        let pngData = makeTestPNGData()
        setMockImageResponse(url: url, data: pngData)

        // Load once to populate disk + memory
        _ = await sut.image(for: url)

        // Create fresh instance with same disk dir (empty memory cache)
        MockURLProtocol.requestHandler = nil
        let sut2 = ImageCacheService(session: TestFixtures.makeMockSession(), cacheDirectory: tempDir)

        // Memory should be empty
        XCTAssertNil(sut2.cachedImage(for: url))

        // Pre-warm should promote from disk to memory
        await sut2.preWarmMemoryCache(for: [url])
        XCTAssertNotNil(sut2.cachedImage(for: url))
    }

    func testPreWarmSkipsAlreadyCachedURLs() async {
        let url = URL(string: "https://example.com/already.png")!
        let pngData = makeTestPNGData()
        setMockImageResponse(url: url, data: pngData)

        // Load once — now in memory + disk
        _ = await sut.image(for: url)
        XCTAssertNotNil(sut.cachedImage(for: url))

        // Pre-warm should succeed without error
        await sut.preWarmMemoryCache(for: [url])
        XCTAssertNotNil(sut.cachedImage(for: url))
    }

    func testPreWarmHandlesMissingDiskFiles() async {
        let url = URL(string: "https://example.com/missing.png")!

        // No image on disk — should not crash
        await sut.preWarmMemoryCache(for: [url])
        XCTAssertNil(sut.cachedImage(for: url))
    }

    func testPreWarmMultipleURLs() async {
        let url1 = URL(string: "https://example.com/multi1.png")!
        let url2 = URL(string: "https://example.com/multi2.png")!
        let pngData = makeTestPNGData()

        // Load both to populate disk
        setMockImageResponse(url: url1, data: pngData)
        _ = await sut.image(for: url1)
        setMockImageResponse(url: url2, data: pngData)
        _ = await sut.image(for: url2)

        // Create fresh instance
        MockURLProtocol.requestHandler = nil
        let sut2 = ImageCacheService(session: TestFixtures.makeMockSession(), cacheDirectory: tempDir)

        await sut2.preWarmMemoryCache(for: [url1, url2])
        XCTAssertNotNil(sut2.cachedImage(for: url1))
        XCTAssertNotNil(sut2.cachedImage(for: url2))
    }
}
