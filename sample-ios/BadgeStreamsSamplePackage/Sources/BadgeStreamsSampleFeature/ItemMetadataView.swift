import SwiftUI

struct ItemMetadataView: View {
    let item: JellyfinItem
    let serverURL: String
    let accessToken: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottomLeading) {
                RemoteImageView(
                    url: JellyfinImageURL.backdrop(serverURL: serverURL, item: item, accessToken: accessToken)
                        ?? JellyfinImageURL.primary(serverURL: serverURL, item: item, accessToken: accessToken),
                    contentMode: .fill
                )
                .aspectRatio(16.0 / 9.0, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                HStack(alignment: .bottom, spacing: 12) {
                    RemoteImageView(url: JellyfinImageURL.primary(
                        serverURL: serverURL,
                        item: item,
                        accessToken: accessToken
                    ))
                    .aspectRatio(item.primaryImageAspectRatio ?? (2.0 / 3.0), contentMode: .fill)
                    .containerRelativeFrame(.horizontal) { length, _ in length * 0.28 }
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(radius: 8)

                    VStack(alignment: .leading, spacing: 6) {
                        if JellyfinImageURL.logo(serverURL: serverURL, item: item, accessToken: accessToken) != nil {
                            RemoteImageView(
                                url: JellyfinImageURL.logo(serverURL: serverURL, item: item, accessToken: accessToken),
                                contentMode: .fit
                            )
                            .containerRelativeFrame(.vertical) { length, _ in length * 0.06 }
                        } else {
                            Text(item.name)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .lineLimit(3)
                        }

                        if !item.metaHeadline.isEmpty {
                            Text(item.metaHeadline)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        ratingsRow
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let tagline = item.taglines?.first, !tagline.isEmpty {
                Text(tagline)
                    .font(.callout.italic())
                    .foregroundStyle(.secondary)
            }

            if let overview = item.overview, !overview.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overview")
                        .font(.headline)
                    Text(overview)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            if let genres = item.genres, !genres.isEmpty {
                metaBlock(title: "Genres", value: genres.joined(separator: " · "))
            }

            if let tags = item.tags, !tags.isEmpty {
                metaBlock(title: "Tags", value: tags.joined(separator: " · "))
            }

            if let studios = item.studios, !studios.isEmpty {
                metaBlock(title: "Studios", value: studios.map(\.name).joined(separator: " · "))
            }

            if let language = item.originalLanguage, !language.isEmpty {
                metaBlock(title: "Language", value: language.uppercased())
            }

            if let originalTitle = item.originalTitle, !originalTitle.isEmpty, originalTitle != item.name {
                metaBlock(title: "Original title", value: originalTitle)
            }

            if let premiereDate = item.premiereDate, !premiereDate.isEmpty {
                metaBlock(title: "Premiere", value: String(premiereDate.prefix(10)))
            }

            providerIdsBlock

            if let urls = item.externalUrls, !urls.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Links")
                        .font(.headline)
                    ForEach(Array(urls.enumerated()), id: \.offset) { _, link in
                        if let name = link.name, let href = link.url, let url = URL(string: href) {
                            Link(name, destination: url)
                                .font(.subheadline)
                        }
                    }
                }
            }

            if let trailers = item.remoteTrailers, !trailers.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Trailers")
                        .font(.headline)
                    ForEach(Array(trailers.enumerated()), id: \.offset) { _, trailer in
                        if let href = trailer.url, let url = URL(string: href) {
                            Link(trailer.name ?? "Trailer", destination: url)
                                .font(.subheadline)
                        }
                    }
                }
            }

            if let people = item.people, !people.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Cast & crew")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(people.prefix(16)) { person in
                                personCell(person)
                            }
                        }
                    }
                }
            }
        }
    }

    private var ratingsRow: some View {
        HStack(spacing: 10) {
            if let communityRating = item.communityRating {
                Label(String(format: "%.1f", communityRating), systemImage: "star.fill")
            }
            if let criticRating = item.criticRating {
                Label(String(format: "%.0f", criticRating), systemImage: "ticket")
            }
            if let childCount = item.childCount, childCount > 0 {
                Label("\(childCount)", systemImage: "square.stack.3d.up")
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white.opacity(0.9))
    }

    @ViewBuilder
    private var providerIdsBlock: some View {
        let pairs = item.providerIds?.pairs ?? []
        if !pairs.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("IDs")
                    .font(.headline)
                ForEach(pairs, id: \.label) { pair in
                    LabeledContent(pair.label, value: pair.value)
                        .font(.subheadline)
                }
            }
        }
    }

    private func metaBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func personCell(_ person: JellyfinPerson) -> some View {
        VStack(spacing: 6) {
            RemoteImageView(url: JellyfinImageURL.person(
                serverURL: serverURL,
                person: person,
                accessToken: accessToken
            ))
            .aspectRatio(1, contentMode: .fill)
            .containerRelativeFrame(.horizontal) { length, _ in length * 0.18 }
            .clipShape(Circle())

            Text(person.name)
                .font(.caption2.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let role = person.role, !role.isEmpty {
                Text(role)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else if let type = person.type {
                Text(type)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerRelativeFrame(.horizontal) { length, _ in length * 0.2 }
    }
}
