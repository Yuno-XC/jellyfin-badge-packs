import SwiftUI

struct LibrariesView: View {
    let settings: AppSettings

    @State private var libraries: [JellyfinItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && libraries.isEmpty {
                ProgressView("Loading libraries…")
            } else if let errorMessage {
                ContentUnavailableView(
                    "Couldn’t load libraries",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else if libraries.isEmpty {
                ContentUnavailableView(
                    settings.hasStoredCredentials
                        ? "No libraries yet"
                        : "One-time setup",
                    systemImage: "books.vertical",
                    description: Text(
                        settings.hasStoredCredentials
                            ? "Pull to refresh."
                            : "Open Settings once, enter AIOM username and password, then you’re done forever."
                    )
                )
            } else {
                List(libraries) { library in
                    NavigationLink(value: library) {
                        if let token = settings.accessToken {
                            ItemRowView(
                                item: library,
                                serverURL: settings.resolvedServerURL,
                                accessToken: token
                            )
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(library.name)
                                    .font(.headline)
                                Text(librarySubtitle(library))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationDestination(for: JellyfinItem.self) { library in
                    ItemsView(settings: settings, parent: library)
                }
            }
        }
        .navigationTitle("Libraries")
        .refreshable { await load() }
        .task { await load() }
        .onChange(of: settings.accessToken) { _, _ in
            Task { await load() }
        }
    }

    private func librarySubtitle(_ library: JellyfinItem) -> String {
        if let collectionType = library.collectionType, !collectionType.isEmpty {
            return collectionType
        }
        return library.type ?? "Library"
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if settings.canAutoSignIn {
            do {
                try await SessionAuth.ensureSignedIn(settings: settings)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        guard settings.isSignedIn,
              let token = settings.accessToken,
              let userId = settings.userId
        else {
            errorMessage = nil
            return
        }

        do {
            let client = try JellyfinClient(
                serverURL: settings.resolvedServerURL,
                accessToken: token,
                userId: userId
            )
            libraries = try await client.libraries()
        } catch {
            // Token may have died mid-flight — one silent re-auth retry.
            if settings.canAutoSignIn {
                do {
                    settings.clearSession()
                    try await SessionAuth.ensureSignedIn(settings: settings)
                    guard let token = settings.accessToken, let userId = settings.userId else { return }
                    let client = try JellyfinClient(
                        serverURL: settings.resolvedServerURL,
                        accessToken: token,
                        userId: userId
                    )
                    libraries = try await client.libraries()
                    return
                } catch {
                    errorMessage = error.localizedDescription
                    return
                }
            }
            errorMessage = error.localizedDescription
        }
    }
}
