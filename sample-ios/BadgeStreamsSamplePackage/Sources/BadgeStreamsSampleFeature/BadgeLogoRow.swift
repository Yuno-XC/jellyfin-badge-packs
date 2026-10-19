import SwiftUI
import UIKit

struct BadgeLogoRow: View {
    let badges: [BadgeRule]

    /// Adaptive logo height so every badge stays visible across Dynamic Type / device sizes.
    @ScaledMetric(relativeTo: .caption) private var logoMaxHeight = 26

    var body: some View {
        BadgeFlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(Array(badges.enumerated()), id: \.element.rowID) { _, badge in
                badgeView(badge)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func badgeView(_ badge: BadgeRule) -> some View {
        if let url = badge.imageURL {
            BadgeRemoteImage(url: url, accessibilityLabel: badge.name, maxHeight: logoMaxHeight) {
                textChip(badge)
            }
        } else {
            textChip(badge)
        }
    }

    private func textChip(_ badge: BadgeRule) -> some View {
        Text(badge.name)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(.secondary.opacity(0.35))
            )
            .accessibilityLabel(badge.name)
    }
}

private struct BadgeFlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widthUsed: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            widthUsed = max(widthUsed, x - spacing)
        }

        let height = y + rowHeight
        let width = maxWidth.isFinite ? maxWidth : widthUsed
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}

/// Loads Fusion/Kingsize badge PNGs with a browser User-Agent.
/// `formatter.betterer.cc` answers 403 without one.
struct BadgeRemoteImage<Fallback: View>: View {
    let url: URL
    let accessibilityLabel: String
    let maxHeight: CGFloat
    @ViewBuilder var fallback: () -> Fallback

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: maxHeight)
                    .accessibilityLabel(accessibilityLabel)
            } else if failed {
                fallback()
            } else {
                ProgressView()
                    .controlSize(.mini)
                    .frame(width: maxHeight, height: maxHeight)
            }
        }
        .task(id: url) { await load() }
    }

    private func load() async {
        failed = false
        image = nil
        do {
            image = try await BadgeImageLoader.shared.image(for: url)
        } catch {
            failed = true
            #if DEBUG
            print("Badge image failed \(url.absoluteString): \(error.localizedDescription)")
            #endif
        }
    }
}

actor BadgeImageLoader {
    static let shared = BadgeImageLoader()

    private var cache: [URL: UIImage] = [:]
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            "Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
            "Referer": "https://formatter.betterer.cc/",
        ]
        return URLSession(configuration: config)
    }()

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache[url] { return cached }
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("image/avif,image/webp,image/apng,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("https://formatter.betterer.cc/", forHTTPHeaderField: "Referer")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200 ... 299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        cache[url] = image
        return image
    }
}
