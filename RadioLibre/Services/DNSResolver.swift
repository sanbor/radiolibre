import Foundation

/// Resolves Radio Browser API servers via DNS lookup of `all.api.radio-browser.info`.
/// Uses `getaddrinfo` + `getnameinfo` for reverse DNS to get hostnames.
enum DNSResolver {
    static func resolveRadioBrowserServers() async throws -> [String] {
        try await Task.detached {
            var hostnames: [String] = []
            var hints = addrinfo()
            hints.ai_family = AF_UNSPEC
            hints.ai_socktype = SOCK_STREAM

            var result: UnsafeMutablePointer<addrinfo>?
            let status = getaddrinfo("all.api.radio-browser.info", nil, &hints, &result)
            guard status == 0, let firstResult = result else {
                if let result { freeaddrinfo(result) }
                throw AppError.serverDiscoveryFailed
            }
            defer { freeaddrinfo(firstResult) }

            var current: UnsafeMutablePointer<addrinfo>? = firstResult
            while let info = current {
                var hostnameBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let nameStatus = getnameinfo(
                    info.pointee.ai_addr,
                    info.pointee.ai_addrlen,
                    &hostnameBuffer,
                    socklen_t(hostnameBuffer.count),
                    nil, 0,
                    NI_NAMEREQD
                )
                if nameStatus == 0 {
                    let hostname = String(cString: hostnameBuffer)
                    if !hostnames.contains(hostname) {
                        hostnames.append(hostname)
                    }
                }
                current = info.pointee.ai_next
            }

            return hostnames
        }.value
    }
}
