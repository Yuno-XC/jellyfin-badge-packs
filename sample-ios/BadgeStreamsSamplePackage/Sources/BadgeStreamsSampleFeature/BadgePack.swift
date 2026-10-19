import Foundation

public struct BadgeRule: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let groupId: String
    public let isEnabled: Bool
    public let pattern: String
    public let imageURL: URL?
    public let tagColor: String?
    public let borderColor: String?
    public let textColor: String?

    public init(
        id: String,
        name: String,
        groupId: String,
        isEnabled: Bool,
        pattern: String,
        imageURL: URL?,
        tagColor: String?,
        borderColor: String?,
        textColor: String?
    ) {
        self.id = id
        self.name = name
        self.groupId = groupId
        self.isEnabled = isEnabled
        self.pattern = pattern
        self.imageURL = imageURL
        self.tagColor = tagColor
        self.borderColor = borderColor
        self.textColor = textColor
    }

    /// Stable ForEach identity when packs share short ids.
    public var rowID: String {
        "\(id)|\(groupId)|\(pattern)|\(imageURL?.absoluteString ?? "")"
    }
}

public enum BadgePackLoader {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 12
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    public static func load(from url: URL) async throws -> [BadgeRule] {
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        let json = try JSONSerialization.jsonObject(with: data)
        return normalize(json)
    }

    /// Loads and merges every pack URL published by the Jellyfin server.
    public static func load(from urls: [URL]) async throws -> [BadgeRule] {
        guard !urls.isEmpty else { return [] }
        var merged: [BadgeRule] = []
        var seen = Set<String>()
        var lastError: Error?
        for url in urls {
            do {
                for rule in try await load(from: url) {
                    let key = "\(rule.id)|\(rule.pattern)|\(rule.groupId)"
                    guard !seen.contains(key) else { continue }
                    seen.insert(key)
                    merged.append(rule)
                }
            } catch {
                lastError = error
                #if DEBUG
                print("Badge pack load failed \(url.absoluteString): \(error.localizedDescription)")
                #endif
            }
        }
        if merged.isEmpty, let lastError {
            throw lastError
        }
        return merged
    }

    /// Match pack rules against version text (joined with spaces; line-by-line for ^/$ patterns).
    public static func match(filename: String, rules: [BadgeRule]) -> [BadgeRule] {
        let lines = filename
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { String($0) }
        guard !lines.isEmpty else { return [] }
        let joined = lines.joined(separator: " ")
        var usedGroups = Set<String>()
        var usedKeys = Set<String>()
        var matched: [BadgeRule] = []
        for rule in rules where rule.isEnabled {
            guard !rule.pattern.isEmpty else { continue }
            guard let compiled = compilePattern(rule.pattern) else { continue }
            let perLine = compiled.source.contains("^") || compiled.source.contains("$")
            let hitsJoined = regexHits(compiled.regex, in: joined)
            let hitsLine = perLine && lines.contains { regexHits(compiled.regex, in: $0) }
            guard hitsJoined || hitsLine else { continue }
            let keys = [
                rule.name.lowercased(),
                rule.imageURL?.absoluteString.lowercased() ?? "",
            ].filter { !$0.isEmpty }
            if keys.contains(where: { usedKeys.contains($0) }) { continue }
            if !rule.groupId.isEmpty {
                if usedGroups.contains(rule.groupId) { continue }
                usedGroups.insert(rule.groupId)
            }
            for key in keys { usedKeys.insert(key) }
            matched.append(rule)
        }
        return matched
    }

    private static func regexHits(_ regex: NSRegularExpression, in text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    /// Strip leading inline flags such as `(?i)` before compiling.
    private static func compilePattern(_ source: String) -> (regex: NSRegularExpression, source: String)? {
        var rest = source
        var options: NSRegularExpression.Options = [.caseInsensitive]
        while let match = rest.range(of: #"^\(\?([a-z]+)\)"#, options: [.regularExpression, .caseInsensitive]) {
            let flags = String(rest[match]).lowercased()
            if flags.contains("m") { options.insert(.anchorsMatchLines) }
            if flags.contains("s") { options.insert(.dotMatchesLineSeparators) }
            rest.removeSubrange(match)
        }
        guard let regex = try? NSRegularExpression(pattern: rest, options: options) else {
            return nil
        }
        return (regex, rest)
    }

    private static func normalize(_ json: Any) -> [BadgeRule] {
        var rawFilters: [[String: Any]] = []
        if let dict = json as? [String: Any] {
            if let filters = dict["filters"] as? [[String: Any]] {
                rawFilters = filters
            } else if let badges = dict["badges"] as? [[String: Any]] {
                rawFilters = badges.enumerated().map { index, badge in
                    [
                        "id": badge["id"] ?? "b-\(index)",
                        "name": badge["label"] ?? badge["name"] as Any,
                        "groupId": badge["group"] ?? badge["groupId"] as Any,
                        "isEnabled": badge["isEnabled"] ?? true,
                        "pattern": badge["match"] ?? badge["pattern"] as Any,
                        "imageURL": badge["image"] ?? badge["imageURL"] as Any,
                        "tagColor": badge["background"] ?? badge["tagColor"] as Any,
                        "borderColor": badge["border"] ?? badge["borderColor"] as Any,
                        "textColor": badge["color"] ?? badge["textColor"] as Any,
                    ]
                }
            }
        } else if let array = json as? [[String: Any]] {
            rawFilters = array
        }

        return rawFilters.compactMap { entry in
            let pattern = string(entry["pattern"]) ?? string(entry["match"]) ?? ""
            guard !pattern.isEmpty else { return nil }
            let name = string(entry["name"]) ?? string(entry["label"]) ?? "?"
            let id = string(entry["id"]) ?? name
            let image = string(entry["imageURL"]) ?? string(entry["image"])
            return BadgeRule(
                id: id,
                name: name,
                groupId: string(entry["groupId"]) ?? string(entry["group"]) ?? "",
                isEnabled: (entry["isEnabled"] as? Bool) ?? true,
                pattern: pattern,
                imageURL: image.flatMap(URL.init(string:)),
                tagColor: string(entry["tagColor"]) ?? string(entry["background"]),
                borderColor: string(entry["borderColor"]) ?? string(entry["border"]),
                textColor: string(entry["textColor"]) ?? string(entry["color"])
            )
        }
    }

    private static func string(_ value: Any?) -> String? {
        guard let value else { return nil }
        if let s = value as? String {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return nil
    }
}
