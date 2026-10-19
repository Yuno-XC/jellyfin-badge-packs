import Foundation
import Testing
@testable import BadgeStreamsSampleFeature

struct BadgeStreamsSampleFeatureTests {
    @Test func mapsStremioBaseToJellyfinSystemInfoPublic() throws {
        let url = try #require(
            BadgePackSource.systemInfoPublicURL(
                from: "http://127.0.0.1:3100/stremio/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
            )
        )
        #expect(url.absoluteString == "http://127.0.0.1:3100/jellyfin/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/System/Info/Public")
    }

    @Test func mapsJellyfinBaseToSystemInfoPublic() throws {
        let url = try #require(
            BadgePackSource.systemInfoPublicURL(
                from: "http://127.0.0.1:3100/jellyfin/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/"
            )
        )
        #expect(url.absoluteString == "http://127.0.0.1:3100/jellyfin/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/System/Info/Public")
    }

    @Test func matchesRemuxAndResolutionFromFilename() {
        let rules = [
            BadgeRule(
                id: "remux",
                name: "Remux",
                groupId: "quality",
                isEnabled: true,
                pattern: #"\bremux\b"#,
                imageURL: nil,
                tagColor: nil,
                borderColor: nil,
                textColor: nil
            ),
            BadgeRule(
                id: "1080",
                name: "1080p",
                groupId: "resolution",
                isEnabled: true,
                pattern: #"\b1080p\b"#,
                imageURL: nil,
                tagColor: nil,
                borderColor: nil,
                textColor: nil
            ),
            BadgeRule(
                id: "4k",
                name: "4K",
                groupId: "resolution",
                isEnabled: true,
                pattern: #"\b(2160p|4k|uhd)\b"#,
                imageURL: nil,
                tagColor: nil,
                borderColor: nil,
                textColor: nil
            ),
        ]

        let matched = BadgePackLoader.match(
            filename: "Shangri.La.Frontier.S02E05.1080p.BluRay.REMUX.NTRX.mkv",
            rules: rules
        )
        #expect(matched.map(\.name) == ["Remux", "1080p"])
    }

    @Test func loadsKingsizePackAndMatchesObsessionFilename() async throws {
        let url = try #require(
            URL(string: "https://raw.githubusercontent.com/kingsizew/badges/main/white_badges.json")
        )
        let rules = try await BadgePackLoader.load(from: url)
        #expect(rules.count > 10)

        let matched = BadgePackLoader.match(
            filename: "Obsession.2025.2160p.DV.Atmos.7.1.FraMeSToR.mkv",
            rules: rules
        )
        let names = Set(matched.map { $0.name.lowercased() })
        #expect(names.contains { $0.contains("4k") || $0.contains("2160") || $0 == "uhd" } || !matched.isEmpty)
    }

    @Test func loadsFusionPackAndMatchesRemuxFilename() async throws {
        let url = try #require(
            URL(string: "https://gist.githubusercontent.com/Yuno-XC/38f0ae025a9d5a29af4cc41ea921df0e/raw/cc973b54ec2da51e27d937db0989d5a27f3e7d87/Fusion.json")
        )
        let rules = try await BadgePackLoader.load(from: url)
        #expect(rules.count > 20)
        #expect(rules.contains(where: { $0.imageURL != nil }))

        let matched = BadgePackLoader.match(
            filename: """
            ✎ Shawshank ⚡
            4K · Remux · HDR · Atmos · 7.1
            The.Shawshank.Redemption.1994.2160p.UHD.BluRay.REMUX.HDR.Atmos.TrueHD.7.1.FraMeSToR.mkv
            """,
            rules: rules
        )
        #expect(!matched.isEmpty)
        let names = matched.map { $0.name.lowercased() }
        #expect(names.contains(where: { $0.contains("remux") }))
        #expect(names.contains(where: { $0.contains("4k") || $0.contains("2160") }))
        #expect(matched.contains(where: { $0.imageURL != nil }))
    }

    @Test func fusionWebReleaseDoesNotMatchBluRay() async throws {
        let url = try #require(
            URL(string: "https://gist.githubusercontent.com/Yuno-XC/38f0ae025a9d5a29af4cc41ea921df0e/raw/cc973b54ec2da51e27d937db0989d5a27f3e7d87/Fusion.json")
        )
        let rules = try await BadgePackLoader.load(from: url)
        let matched = BadgePackLoader.match(
            filename: """
            Cocorico.2.2026.FRENCH.HDR.DV.2160p.WEB.H265-SUPPLY.mkv
            2160p · WEB · DV · HDR10+ · AAC · DD 5.1 | ◈ 17 GB · 24.7 Mbps · SUPPLY | ғʀ · sub  2700.
            """,
            rules: rules
        )
        let names = matched.map { $0.name.lowercased() }
        #expect(names.contains(where: { $0.contains("4k") }))
        #expect(names.contains(where: { $0.contains("web") }))
        #expect(!names.contains(where: { $0.contains("bluray") || $0.contains("blu-ray") }))
        #expect(matched.count >= 3)
        #expect(matched.contains(where: { $0.imageURL != nil }))
        let rowIDs = matched.map(\.rowID)
        #expect(Set(rowIDs).count == rowIDs.count)
    }
}
