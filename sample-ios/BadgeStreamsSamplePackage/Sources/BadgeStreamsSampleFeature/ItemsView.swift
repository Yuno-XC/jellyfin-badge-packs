import SwiftUI

struct ItemsView: View {
    let settings: AppSettings
    let parent: JellyfinItem

    @State private var items: [JellyfinItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && items.isEmpty {
                ProgressView("Loading titles…")
            } else if let errorMessage {
                ContentUnavailableView(
                    "Couldn’t load titles",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if items.isEmpty {
                ContentUnavailableView(
                    "No titles",
                    systemImage: "film",
                    description: Text("This library returned no movies or series.")
                )
            } else {
                List(items) { item in
                    if Self.isFolder(item) {
                        NavigationLink {
                            ItemsView(settings: settings, parent: item)
                        } label: {
                            row(for: item)
                        }
                    } else {
                        NavigationLink(value: TitleRoute(item: item)) {
                            row(for: item)
                        }
                    }
                }
                .listStyle(.plain)
                .navigationDestination(for: TitleRoute.self) { route in
                    TitleVersionsView(settings: settings, item: route.item)
                }
            }
        }
        .navigationTitle(parent.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
    }

    @ViewBuilder
    private func row(for item: JellyfinItem) -> some View {
        if let token = settings.accessToken {
            ItemRowView(
                item: item,
                serverURL: settings.resolvedServerURL,
                accessToken: token
            )
        } else {
            Text(item.name)
        }
    }

    private static func isFolder(_ item: JellyfinItem) -> Bool {
        let type = (item.type ?? "").lowercased()
        return type == "series" || type == "season" || type == "folder" || type == "collectionfolder"
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        guard let token = settings.accessToken, let userId = settings.userId else {
            errorMessage = "Not signed in."
            return
        }
        do {
            let client = try JellyfinClient(
                serverURL: settings.resolvedServerURL,
                accessToken: token,
                userId: userId
            )
            let parentType = (parent.type ?? "").lowercased()
            if parentType == "series" || parentType == "season" {
                items = try await client.children(parentId: parent.id)
            } else {
                items = try await client.items(parentId: parent.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct TitleRoute: Hashable {
    let item: JellyfinItem
}
