import SwiftUI

struct TitleVersionsView: View {
    let settings: AppSettings
    let item: JellyfinItem

    @State private var detail: JellyfinItem?
    @State private var sources: [JellyfinMediaSource] = []
    @State private var rules: [BadgeRule] = []
    @State private var isLoading = false
    @State private var packsLoading = false
    @State private var packsReady = false
    @State private var errorMessage: String?
    @State private var packStatus: String?

    private var displayItem: JellyfinItem { detail ?? item }

    var body: some View {
        List {
            if let token = settings.accessToken {
                Section {
                    ItemMetadataView(
                        item: displayItem,
                        serverURL: settings.resolvedServerURL,
                        accessToken: token
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }

            if let packStatus {
                Section {
                    Text(packStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if isLoading && sources.isEmpty {
                Section {
                    ProgressView("Loading versions…")
                }
            } else if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            } else if sources.isEmpty {
                Section {
                    Text("No stream versions yet. Check the AIOS stream addon URL in AIOM.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Versions") {
                    ForEach(sources) { source in
                        VersionCardView(
                            source: source,
                            badges: BadgePackLoader.match(
                                filename: source.badgeMatchText,
                                rules: rules
                            ),
                            packsReady: packsReady || (!packsLoading && !rules.isEmpty)
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(displayItem.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        packsLoading = true
        packsReady = false
        errorMessage = nil
        defer { isLoading = false }

        // Packs + versions in parallel so logos appear as soon as both are ready.
        async let detailTask: Void = loadDetail()
        async let sourcesTask: Void = loadSources()
        async let packTask: Void = loadPack()
        _ = await (detailTask, sourcesTask, packTask)
    }

    private func loadPack() async {
        packsLoading = true
        defer {
            packsLoading = false
            packsReady = true
        }
        let source = settings.badgePackSourceURL
        guard !source.isEmpty else {
            rules = []
            packStatus = "Set the AIOS URL under Settings → Badge packs (or use AIOS as the Jellyfin URL)"
            return
        }
        do {
            let urls = try await BadgePackSource.loadPackURLs(streamAddonBase: source)
            guard !urls.isEmpty else {
                rules = []
                packStatus = "No badge packs on AIOS System/Info — add packs in AIOS Configure → Miscellaneous → Badge Packs, then Save"
                return
            }
            rules = try await BadgePackLoader.load(from: urls)
            packStatus = "Loaded \(rules.count) badges from \(urls.count) AIOS pack(s)"
        } catch {
            rules = []
            packStatus = "Pack load failed: \(error.localizedDescription)"
        }
    }

    private func loadDetail() async {
        guard let token = settings.accessToken, let userId = settings.userId else { return }
        do {
            let client = try JellyfinClient(
                serverURL: settings.resolvedServerURL,
                accessToken: token,
                userId: userId
            )
            detail = try await client.itemDetail(itemId: item.id)
        } catch {
            #if DEBUG
            print("Item detail failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadSources() async {
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
            sources = try await client.mediaSources(itemId: item.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
