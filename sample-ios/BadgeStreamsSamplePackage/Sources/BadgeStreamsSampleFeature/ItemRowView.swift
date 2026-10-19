import SwiftUI

struct ItemRowView: View {
    let item: JellyfinItem
    let serverURL: String
    let accessToken: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RemoteImageView(url: JellyfinImageURL.primary(
                serverURL: serverURL,
                item: item,
                accessToken: accessToken
            ))
            .aspectRatio(item.primaryImageAspectRatio ?? (2.0 / 3.0), contentMode: .fill)
            .containerRelativeFrame(.horizontal) { length, _ in length * 0.22 }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if !item.metaHeadline.isEmpty {
                    Text(item.metaHeadline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let collectionType = item.collectionType, !collectionType.isEmpty {
                    Text(collectionType)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let type = item.type {
                    Text(type)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let rating = item.communityRating {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let genres = item.genres, !genres.isEmpty {
                    Text(genres.prefix(3).joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                if let overview = item.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                if let childCount = item.childCount, childCount > 0, (item.type ?? "").lowercased().contains("folder") || item.collectionType != nil {
                    Text("\(childCount) titles")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
