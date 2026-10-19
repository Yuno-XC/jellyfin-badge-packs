import Foundation

enum SessionAuth {
    /// Validates the saved token, or re-signs in with Keychain credentials.
    @MainActor
    static func ensureSignedIn(settings: AppSettings) async throws {
        guard settings.canAutoSignIn else {
            throw JellyfinClientError.message("No saved AIOM login")
        }

        if settings.isSignedIn {
            let client = try JellyfinClient(
                serverURL: settings.resolvedServerURL,
                accessToken: settings.accessToken,
                userId: settings.userId
            )
            if try await client.validateSession() {
                return
            }
            settings.clearSession()
        }

        let client = try JellyfinClient(serverURL: settings.resolvedServerURL)
        let auth = try await client.signIn(username: settings.username, password: settings.password)
        settings.accessToken = auth.accessToken
        settings.userId = auth.user.id
    }
}
