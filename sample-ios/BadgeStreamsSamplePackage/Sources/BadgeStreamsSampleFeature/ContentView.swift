import SwiftUI

public struct ContentView: View {
    @State private var settings = AppSettings()
    @State private var selectedTab = 0
    @State private var isRestoringSession = false
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LibrariesView(settings: settings)
            }
            .tabItem { Label("Browse", systemImage: "film.stack") }
            .tag(0)

            NavigationStack {
                SettingsView(settings: settings) {
                    selectedTab = 0
                }
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(1)
        }
        .overlay {
            if isRestoringSession {
                ProgressView("Keeping you signed in…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .task {
            await restoreSessionQuietly()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await restoreSessionQuietly() }
        }
    }

    private func restoreSessionQuietly() async {
        guard settings.canAutoSignIn else {
            // First launch only — need credentials once.
            if !settings.isSignedIn {
                selectedTab = 1
            }
            return
        }

        isRestoringSession = true
        defer { isRestoringSession = false }

        do {
            try await SessionAuth.ensureSignedIn(settings: settings)
            selectedTab = 0
        } catch {
            // Keep Browse selected; LibrariesView will retry. Never clear Keychain password.
            #if DEBUG
            print("Session restore failed: \(error.localizedDescription)")
            #endif
        }
    }
}
