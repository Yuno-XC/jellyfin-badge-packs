import Foundation

public enum JellyfinClientError: LocalizedError {
    case invalidServerURL
    case httpStatus(Int)
    case message(String)
    case timedOut(String)
    case unreachable(String)

    public var errorDescription: String? {
        switch self {
        case .invalidServerURL: return "Invalid server URL"
        case .httpStatus(let code): return "Server answered \(code)"
        case .message(let text): return text
        case .timedOut(let url): return "Timed out talking to \(url)"
        case .unreachable(let url): return "Cannot reach \(url)"
        }
    }
}

public actor JellyfinClient {
    private let session: URLSession
    private var baseURL: URL
    private var accessToken: String?
    private var userId: String?

    private let clientName = "BadgeStreamsSample"
    private let deviceName = "iPhone"
    private let deviceId: String
    private let version = "1.0.0"

    public init(serverURL: String, accessToken: String? = nil, userId: String? = nil) throws {
        guard let url = Self.normalizeBaseURL(serverURL) else {
            throw JellyfinClientError.invalidServerURL
        }
        self.baseURL = url
        self.accessToken = accessToken
        self.userId = userId
        self.deviceId = UIDeviceStableId.value
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 45
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    public func updateServerURL(_ serverURL: String) throws {
        guard let url = Self.normalizeBaseURL(serverURL) else {
            throw JellyfinClientError.invalidServerURL
        }
        baseURL = url
    }

    public func signIn(username: String, password: String) async throws -> JellyfinAuthResult {
        var request = try makeRequest(path: "Users/AuthenticateByName", method: "POST", authorized: false)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "Username": username,
            "Pw": password,
        ])
        let result: JellyfinAuthResult = try await decode(request)
        accessToken = result.accessToken
        userId = result.user.id
        return result
    }

    /// Returns true when the stored token still works. A 401 means re-auth, not failure.
    public func validateSession() async throws -> Bool {
        guard accessToken != nil, userId != nil else { return false }
        do {
            let _: JellyfinUser = try await decode(makeRequest(path: "Users/Me"))
            return true
        } catch JellyfinClientError.httpStatus(401) {
            return false
        }
    }

    public func libraries() async throws -> [JellyfinItem] {
        guard let userId else { throw JellyfinClientError.message("Not signed in") }
        guard var components = URLComponents(
            url: url(joining: "Users/\(userId)/Views"),
            resolvingAgainstBaseURL: false
        ) else {
            throw JellyfinClientError.invalidServerURL
        }
        components.queryItems = [
            URLQueryItem(name: "IncludeHidden", value: "false"),
            URLQueryItem(name: "Fields", value: JellyfinFieldSets.catalog),
        ]
        guard let requestURL = components.url else { throw JellyfinClientError.invalidServerURL }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        applyHeaders(&request, authorized: true)
        let response: JellyfinItemsResponse = try await decode(request)
        return response.items
    }

    public func items(parentId: String) async throws -> [JellyfinItem] {
        guard let userId else { throw JellyfinClientError.message("Not signed in") }
        guard var components = URLComponents(url: url(joining: "Users/\(userId)/Items"), resolvingAgainstBaseURL: false) else {
            throw JellyfinClientError.invalidServerURL
        }
        // AIOM catalogs expose Movie and Series rows (not Episode at the library root).
        components.queryItems = [
            URLQueryItem(name: "ParentId", value: parentId),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "IncludeItemTypes", value: "Movie,Series"),
            URLQueryItem(name: "Fields", value: JellyfinFieldSets.catalog),
            URLQueryItem(name: "Limit", value: "50"),
            URLQueryItem(name: "SortBy", value: "SortName"),
        ]
        guard let url = components.url else { throw JellyfinClientError.invalidServerURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request, authorized: true)
        let response: JellyfinItemsResponse = try await decode(request)
        return response.items
    }

    public func children(parentId: String) async throws -> [JellyfinItem] {
        guard let userId else { throw JellyfinClientError.message("Not signed in") }
        guard var components = URLComponents(
            url: url(joining: "Users/\(userId)/Items"),
            resolvingAgainstBaseURL: false
        ) else {
            throw JellyfinClientError.invalidServerURL
        }
        components.queryItems = [
            URLQueryItem(name: "ParentId", value: parentId),
            URLQueryItem(name: "Fields", value: JellyfinFieldSets.catalog),
            URLQueryItem(name: "Limit", value: "100"),
            URLQueryItem(name: "SortBy", value: "SortName"),
        ]
        guard let requestURL = components.url else { throw JellyfinClientError.invalidServerURL }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        applyHeaders(&request, authorized: true)
        let response: JellyfinItemsResponse = try await decode(request)
        return response.items
    }

    public func itemDetail(itemId: String) async throws -> JellyfinItem {
        guard let userId else { throw JellyfinClientError.message("Not signed in") }
        guard var components = URLComponents(
            url: url(joining: "Users/\(userId)/Items/\(itemId)"),
            resolvingAgainstBaseURL: false
        ) else {
            throw JellyfinClientError.invalidServerURL
        }
        components.queryItems = [
            URLQueryItem(name: "Fields", value: JellyfinFieldSets.catalog),
        ]
        guard let detailURL = components.url else { throw JellyfinClientError.invalidServerURL }
        var request = URLRequest(url: detailURL)
        request.httpMethod = "GET"
        applyHeaders(&request, authorized: true)
        return try await decode(request)
    }

    /// Pack JSON URLs from `System/Info` (`aiostreams.defaultBadgePacks`).
    public func badgePackURLs() async throws -> [URL] {
        let path = accessToken == nil ? "System/Info/Public" : "System/Info"
        let request = try makeRequest(path: path, authorized: accessToken != nil)
        let info: JellyfinSystemInfo = try await decode(request)
        return info.defaultBadgePacks.compactMap { raw in
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.lowercased().hasPrefix("http") else { return nil }
            return URL(string: trimmed)
        }
    }

    public func mediaSources(itemId: String) async throws -> [JellyfinMediaSource] {
        guard let userId else { throw JellyfinClientError.message("Not signed in") }

        // Refresh=true asks AIOM to resolve real stream addon versions (not placeholders).
        var request = try makeRequest(path: "Items/\(itemId)/PlaybackInfo", method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "UserId": userId,
            "IsPlayback": false,
            "AutoOpenLiveStream": false,
            "Refresh": true,
        ])
        do {
            let info: JellyfinPlaybackInfo = try await decode(request)
            let real = info.mediaSources.filter { !Self.isPlaceholder($0) }
            if !real.isEmpty { return real }
            if !info.mediaSources.isEmpty { return info.mediaSources }
        } catch JellyfinClientError.httpStatus(404) {
            // Series/Season are folders — caller should drill down.
        }

        guard var components = URLComponents(
            url: url(joining: "Users/\(userId)/Items/\(itemId)"),
            resolvingAgainstBaseURL: false
        ) else {
            throw JellyfinClientError.invalidServerURL
        }
        components.queryItems = [
            URLQueryItem(name: "Fields", value: "MediaSources,Path"),
        ]
        guard let detailURL = components.url else { throw JellyfinClientError.invalidServerURL }
        var detailRequest = URLRequest(url: detailURL)
        applyHeaders(&detailRequest, authorized: true)
        let item: JellyfinItem = try await decode(detailRequest)
        let sources = item.mediaSources ?? []
        let real = sources.filter { !Self.isPlaceholder($0) }
        return real.isEmpty ? sources : real
    }

    private static func isPlaceholder(_ source: JellyfinMediaSource) -> Bool {
        let name = (source.name ?? "").lowercased()
        let path = (source.path ?? "").lowercased()
        return path.contains("placeholder")
            || name.contains("load the stream")
            || name.contains("streams load when played")
    }

    private func makeRequest(path: String, method: String = "GET", authorized: Bool = true) throws -> URLRequest {
        var request = URLRequest(url: url(joining: path))
        request.httpMethod = method
        applyHeaders(&request, authorized: authorized)
        return request
    }

    /// Joins relative API paths onto the Jellyfin base without wiping `/jellyfin/<uuid>`.
    private func url(joining path: String) -> URL {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return baseURL.appending(path: trimmed)
    }

    private func applyHeaders(_ request: inout URLRequest, authorized: Bool) {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        var auth = "MediaBrowser Client=\"\(clientName)\", Device=\"\(deviceName)\", DeviceId=\"\(deviceId)\", Version=\"\(version)\""
        if authorized, let accessToken, !accessToken.isEmpty {
            auth += ", Token=\"\(accessToken)\""
        }
        request.setValue(auth, forHTTPHeaderField: "Authorization")
        request.setValue(auth, forHTTPHeaderField: "X-Emby-Authorization")
    }

    private func decode<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
                #if DEBUG
                print("Jellyfin HTTP \(http.statusCode) \(request.url?.absoluteString ?? "") body=\(String(data: data, encoding: .utf8) ?? "")")
                #endif
                throw JellyfinClientError.httpStatus(http.statusCode)
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as JellyfinClientError {
            throw error
        } catch let urlError as URLError {
            let target = request.url?.absoluteString ?? baseURL.absoluteString
            #if DEBUG
            print("Jellyfin URLError \(urlError.code.rawValue) \(target)")
            #endif
            switch urlError.code {
            case .timedOut:
                throw JellyfinClientError.timedOut(target)
            case .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet, .dnsLookupFailed:
                throw JellyfinClientError.unreachable(target)
            default:
                throw JellyfinClientError.message(urlError.localizedDescription)
            }
        } catch {
            throw JellyfinClientError.message(error.localizedDescription)
        }
    }

    private static func normalizeBaseURL(_ raw: String) -> URL? {
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        return URL(string: trimmed)
    }
}

enum UIDeviceStableId {
    static let value: String = {
        if let existing = UserDefaults.standard.string(forKey: "badge.deviceId") {
            return existing
        }
        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: "badge.deviceId")
        return created
    }()
}
