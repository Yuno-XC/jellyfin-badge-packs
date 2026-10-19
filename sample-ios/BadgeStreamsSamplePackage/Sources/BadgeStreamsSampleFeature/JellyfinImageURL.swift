import Foundation

enum JellyfinImageKind: String {
    case primary = "Primary"
    case backdrop = "Backdrop"
    case logo = "Logo"
    case thumb = "Thumb"
    case banner = "Banner"
}

enum JellyfinImageURL {
    /// Public image URL using `api_key` so SwiftUI AsyncImage can load without custom headers.
    static func make(
        serverURL: String,
        itemId: String,
        kind: JellyfinImageKind,
        tag: String?,
        accessToken: String,
        maxHeightFractionOf1080: Double = 0.4
    ) -> URL? {
        var base = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while base.hasSuffix("/") { base.removeLast() }
        guard var components = URLComponents(string: "\(base)/Items/\(itemId)/Images/\(kind.rawValue)") else {
            return nil
        }
        var items: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: accessToken),
            // Relative to common poster height budget; server scales.
            URLQueryItem(name: "maxHeight", value: String(Int((1080 * maxHeightFractionOf1080).rounded()))),
            URLQueryItem(name: "quality", value: "90"),
        ]
        if let tag, !tag.isEmpty {
            items.append(URLQueryItem(name: "tag", value: tag))
        }
        components.queryItems = items
        return components.url
    }

    static func primary(serverURL: String, item: JellyfinItem, accessToken: String) -> URL? {
        make(
            serverURL: serverURL,
            itemId: item.id,
            kind: .primary,
            tag: item.imageTags?.primary,
            accessToken: accessToken,
            maxHeightFractionOf1080: 0.55
        )
    }

    static func backdrop(serverURL: String, item: JellyfinItem, accessToken: String) -> URL? {
        make(
            serverURL: serverURL,
            itemId: item.id,
            kind: .backdrop,
            tag: item.backdropImageTags?.first,
            accessToken: accessToken,
            maxHeightFractionOf1080: 0.7
        )
    }

    static func logo(serverURL: String, item: JellyfinItem, accessToken: String) -> URL? {
        make(
            serverURL: serverURL,
            itemId: item.id,
            kind: .logo,
            tag: item.imageTags?.logo,
            accessToken: accessToken,
            maxHeightFractionOf1080: 0.25
        )
    }

    static func person(serverURL: String, person: JellyfinPerson, accessToken: String) -> URL? {
        make(
            serverURL: serverURL,
            itemId: person.id,
            kind: .primary,
            tag: person.primaryImageTag,
            accessToken: accessToken,
            maxHeightFractionOf1080: 0.25
        )
    }
}
