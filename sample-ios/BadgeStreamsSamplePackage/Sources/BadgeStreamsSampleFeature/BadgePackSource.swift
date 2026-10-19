import Foundation

/// Resolves badge-pack JSON URLs from a **modified AIOS** Jellyfin `System/Info`.
/// Works when AIOS is used directly, or wrapped as the stream addon behind stock AIOM.
public enum BadgePackSource {
    /// Map an AIOS install / Stremio / Jellyfin base to `…/System/Info/Public`.
    public static func systemInfoPublicURL(from streamBase: String) -> URL? {
        let trimmed = streamBase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, var components = URLComponents(string: trimmed) else { return nil }
        guard let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }

        var path = components.path
        while path.hasSuffix("/") { path.removeLast() }

        if path.range(of: #"/stremio(/|$)"#, options: .regularExpression) != nil {
            path = path.replacingOccurrences(
                of: #"/stremio(/|$)"#,
                with: "/jellyfin$1",
                options: .regularExpression
            )
        } else if path.range(of: #"/jellyfin(/|$)"#, options: .regularExpression) == nil {
            path = (path.isEmpty ? "" : path) + "/jellyfin"
            path = path.replacingOccurrences(of: #"/{2,}"#, with: "/", options: .regularExpression)
        }

        if path.hasSuffix("/manifest.json") {
            path = String(path.dropLast("/manifest.json".count))
            while path.hasSuffix("/") { path.removeLast() }
        }

        path += "/System/Info/Public"
        path = path.replacingOccurrences(of: #"/{2,}"#, with: "/", options: .regularExpression)

        components.path = path
        components.query = nil
        components.fragment = nil
        return components.url
    }

    public static func loadPackURLs(streamAddonBase: String) async throws -> [URL] {
        guard let infoURL = systemInfoPublicURL(from: streamAddonBase) else {
            throw URLError(.badURL)
        }
        let session: URLSession = {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 8
            config.timeoutIntervalForResource = 12
            return URLSession(configuration: config)
        }()
        let (data, response) = try await session.data(from: infoURL)
        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        let info = try JSONDecoder().decode(JellyfinSystemInfo.self, from: data)
        return info.defaultBadgePacks.compactMap { raw in
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.lowercased().hasPrefix("http") else { return nil }
            return URL(string: trimmed)
        }
    }
}
