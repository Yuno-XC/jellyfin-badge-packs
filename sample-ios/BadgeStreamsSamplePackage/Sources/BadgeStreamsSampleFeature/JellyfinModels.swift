import Foundation

public struct JellyfinUser: Decodable, Sendable {
    public let id: String
    public let name: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
    }
}

public struct JellyfinAuthResult: Decodable, Sendable {
    public let user: JellyfinUser
    public let accessToken: String

    enum CodingKeys: String, CodingKey {
        case user = "User"
        case accessToken = "AccessToken"
    }
}

public struct JellyfinImageTags: Decodable, Hashable, Sendable {
    public let primary: String?
    public let logo: String?
    public let thumb: String?
    public let banner: String?
    public let disc: String?
    public let art: String?

    enum CodingKeys: String, CodingKey {
        case primary = "Primary"
        case logo = "Logo"
        case thumb = "Thumb"
        case banner = "Banner"
        case disc = "Disc"
        case art = "Art"
    }
}

public struct JellyfinPerson: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let role: String?
    public let type: String?
    public let primaryImageTag: String?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case role = "Role"
        case type = "Type"
        case primaryImageTag = "PrimaryImageTag"
    }
}

public struct JellyfinNamedId: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    public let name: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
    }
}

public struct JellyfinExternalURL: Decodable, Hashable, Sendable {
    public let name: String?
    public let url: String?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case url = "Url"
    }
}

public struct JellyfinProviderIds: Decodable, Hashable, Sendable {
    public let imdb: String?
    public let tmdb: String?
    public let tvdb: String?
    public let mal: String?
    public let anilist: String?

    enum CodingKeys: String, CodingKey {
        case imdb = "Imdb"
        case tmdb = "Tmdb"
        case tvdb = "Tvdb"
        case mal = "Mal"
        case anilist = "AniList"
    }

    public var pairs: [(label: String, value: String)] {
        var out: [(String, String)] = []
        if let imdb, !imdb.isEmpty { out.append(("IMDb", imdb)) }
        if let tmdb, !tmdb.isEmpty { out.append(("TMDB", tmdb)) }
        if let tvdb, !tvdb.isEmpty { out.append(("TVDB", tvdb)) }
        if let mal, !mal.isEmpty { out.append(("MAL", mal)) }
        if let anilist, !anilist.isEmpty { out.append(("AniList", anilist)) }
        return out
    }
}

public struct JellyfinItem: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let sortName: String?
    public let originalTitle: String?
    public let type: String?
    public let collectionType: String?
    public let mediaType: String?
    public let isFolder: Bool?
    public let parentId: String?
    public let overview: String?
    public let productionYear: Int?
    public let premiereDate: String?
    public let officialRating: String?
    public let communityRating: Double?
    public let criticRating: Double?
    public let runTimeTicks: Int64?
    public let childCount: Int?
    public let genres: [String]?
    public let tags: [String]?
    public let taglines: [String]?
    public let studios: [JellyfinNamedId]?
    public let people: [JellyfinPerson]?
    public let providerIds: JellyfinProviderIds?
    public let externalUrls: [JellyfinExternalURL]?
    public let remoteTrailers: [JellyfinExternalURL]?
    public let imageTags: JellyfinImageTags?
    public let backdropImageTags: [String]?
    public let primaryImageAspectRatio: Double?
    public let originalLanguage: String?
    public let mediaSources: [JellyfinMediaSource]?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case sortName = "SortName"
        case originalTitle = "OriginalTitle"
        case type = "Type"
        case collectionType = "CollectionType"
        case mediaType = "MediaType"
        case isFolder = "IsFolder"
        case parentId = "ParentId"
        case overview = "Overview"
        case productionYear = "ProductionYear"
        case premiereDate = "PremiereDate"
        case officialRating = "OfficialRating"
        case communityRating = "CommunityRating"
        case criticRating = "CriticRating"
        case runTimeTicks = "RunTimeTicks"
        case childCount = "ChildCount"
        case genres = "Genres"
        case tags = "Tags"
        case taglines = "Taglines"
        case studios = "Studios"
        case people = "People"
        case providerIds = "ProviderIds"
        case externalUrls = "ExternalUrls"
        case remoteTrailers = "RemoteTrailers"
        case imageTags = "ImageTags"
        case backdropImageTags = "BackdropImageTags"
        case primaryImageAspectRatio = "PrimaryImageAspectRatio"
        case originalLanguage = "OriginalLanguage"
        case mediaSources = "MediaSources"
    }

    public var runtimeMinutes: Int? {
        guard let runTimeTicks, runTimeTicks > 0 else { return nil }
        return Int(runTimeTicks / 10_000_000 / 60)
    }

    public var metaHeadline: String {
        var parts: [String] = []
        if let productionYear { parts.append(String(productionYear)) }
        if let officialRating, !officialRating.isEmpty { parts.append(officialRating) }
        if let runtimeMinutes { parts.append("\(runtimeMinutes) min") }
        if let type, !type.isEmpty { parts.append(type) }
        return parts.joined(separator: " · ")
    }
}

public struct JellyfinMediaSourceAIOStreams: Decodable, Hashable, Sendable {
    public let name: String?
    public let description: String?
    public let filename: String?

    enum CodingKeys: String, CodingKey {
        case name, description, filename
    }
}

public struct JellyfinMediaSource: Identifiable, Decodable, Hashable, Sendable {
    public let id: String
    public let name: String?
    public let path: String?
    public let container: String?
    public let size: Int64?
    public let bitrate: Int?
    public let aiostreams: JellyfinMediaSourceAIOStreams?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case path = "Path"
        case container = "Container"
        case size = "Size"
        case bitrate = "Bitrate"
        case aiostreams
    }

    /// Formatter name + description from the stream addon.
    public var displayText: String {
        let fromAddon = [aiostreams?.name, aiostreams?.description]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !fromAddon.isEmpty {
            return fromAddon.joined(separator: "\n")
        }
        return name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? id
    }

    /// Text used for pack regex matching (filename + description).
    public var badgeMatchText: String {
        var parts: [String] = []
        if let filename = aiostreams?.filename, !filename.isEmpty {
            parts.append(filename)
        } else if let path, path.hasPrefix("/p2p/") {
            parts.append(String(path.dropFirst(5)))
        } else if let path, !path.isEmpty, !path.hasPrefix("http") {
            parts.append((path as NSString).lastPathComponent)
        }
        if let description = aiostreams?.description, !description.isEmpty {
            parts.append(Self.fusionSafeMatchText(description))
        }
        if parts.isEmpty {
            if let name = aiostreams?.name, !name.isEmpty {
                parts.append(Self.fusionSafeMatchText(name))
            }
            if let name, !name.isEmpty {
                parts.append(Self.fusionSafeMatchText(name))
            }
        }
        let joined = parts.joined(separator: "\n")
        if !joined.isEmpty { return joined }
        return Self.fusionSafeMatchText(displayText)
    }

    /// Fusion BluRay patterns treat bare "4K"/"UHD" as BluRay; map those labels to 2160p for matching only.
    private static func fusionSafeMatchText(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"\b4K\b"#, with: "2160p", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"\bUHD\b"#, with: "2160p", options: [.regularExpression, .caseInsensitive])
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

public struct JellyfinItemsResponse: Decodable, Sendable {
    public let items: [JellyfinItem]

    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }
}

public struct JellyfinPlaybackInfo: Decodable, Sendable {
    public let mediaSources: [JellyfinMediaSource]

    enum CodingKeys: String, CodingKey {
        case mediaSources = "MediaSources"
    }
}

public struct JellyfinAIOStreamsInfo: Decodable, Sendable {
    public let defaultBadgePacks: [String]

    enum CodingKeys: String, CodingKey {
        case defaultBadgePacks
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultBadgePacks = try container.decodeIfPresent([String].self, forKey: .defaultBadgePacks) ?? []
    }
}

public struct JellyfinSystemInfo: Decodable, Sendable {
    public let serverName: String?
    public let aiostreams: JellyfinAIOStreamsInfo?

    enum CodingKeys: String, CodingKey {
        case serverName = "ServerName"
        case aiostreams
    }

    public var defaultBadgePacks: [String] {
        aiostreams?.defaultBadgePacks ?? []
    }
}

enum JellyfinFieldSets {
    static let catalog = [
        "Overview", "Genres", "Tags", "Taglines", "Studios", "People",
        "CommunityRating", "CriticRating", "OfficialRating",
        "ProductionYear", "PremiereDate", "RunTimeTicks", "ChildCount",
        "ImageTags", "BackdropImageTags", "PrimaryImageAspectRatio",
        "ProviderIds", "ExternalUrls", "RemoteTrailers", "OriginalTitle",
        "OriginalLanguage", "MediaSources", "Path", "SortName",
    ].joined(separator: ",")
}
