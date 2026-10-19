import Foundation
import Observation

@Observable
@MainActor
public final class AppSettings {
    private enum Keys {
        static let serverURL = "aiom.serverURL"
        static let streamAddonURL = "aiom.streamAddonURL"
        static let username = "aiom.username"
        static let userId = "aiom.userId"
        static let passwordDefaultsLegacy = "aiom.password"
        static let accessTokenDefaultsLegacy = "aiom.accessToken"
        static let badgePackURLLegacy = "badge.packURL"
    }

    private enum KeychainAccounts {
        static let password = "password"
        static let accessToken = "accessToken"
    }

    public var serverURL: String {
        didSet { UserDefaults.standard.set(serverURL, forKey: Keys.serverURL) }
    }

    /// Modified AIOS base (Jellyfin or Stremio URL). Pack list is read from its System/Info.
    public var streamAddonURL: String {
        didSet { UserDefaults.standard.set(streamAddonURL, forKey: Keys.streamAddonURL) }
    }

    public var username: String {
        didSet { UserDefaults.standard.set(username, forKey: Keys.username) }
    }

    public var password: String {
        didSet { persistPassword(password) }
    }

    public var accessToken: String? {
        didSet { persistAccessToken(accessToken) }
    }

    public var userId: String? {
        didSet { UserDefaults.standard.set(userId, forKey: Keys.userId) }
    }

    public var isSignedIn: Bool {
        !(accessToken ?? "").isEmpty && !(userId ?? "").isEmpty
    }

    public var canAutoSignIn: Bool {
        !serverURL.isEmpty && !username.isEmpty && !password.isEmpty
    }

    public var hasStoredCredentials: Bool {
        !username.isEmpty && !password.isEmpty
    }

    public var resolvedServerURL: String { serverURL }

    /// Base used to load `aiostreams.defaultBadgePacks` (AIOS). Falls back to the Jellyfin URL.
    public var badgePackSourceURL: String {
        let addon = streamAddonURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !addon.isEmpty { return addon }
        return serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public init() {
        let defaults = UserDefaults.standard
        serverURL = defaults.string(forKey: Keys.serverURL) ?? ""
        streamAddonURL = defaults.string(forKey: Keys.streamAddonURL) ?? ""
        username = defaults.string(forKey: Keys.username) ?? ""
        userId = defaults.string(forKey: Keys.userId)
        defaults.removeObject(forKey: Keys.badgePackURLLegacy)

        if let keychainPassword = KeychainStore.get(account: KeychainAccounts.password), !keychainPassword.isEmpty {
            password = keychainPassword
        } else if let legacyPassword = defaults.string(forKey: Keys.passwordDefaultsLegacy), !legacyPassword.isEmpty {
            password = legacyPassword
            Self.persistPassword(legacyPassword)
            defaults.removeObject(forKey: Keys.passwordDefaultsLegacy)
        } else {
            password = ""
        }

        if let keychainToken = KeychainStore.get(account: KeychainAccounts.accessToken), !keychainToken.isEmpty {
            accessToken = keychainToken
        } else if let legacyToken = defaults.string(forKey: Keys.accessTokenDefaultsLegacy), !legacyToken.isEmpty {
            accessToken = legacyToken
            Self.persistAccessToken(legacyToken)
            defaults.removeObject(forKey: Keys.accessTokenDefaultsLegacy)
        } else {
            accessToken = nil
        }
    }

    public func clearSession() {
        accessToken = nil
        userId = nil
    }

    public func clearCredentials() {
        clearSession()
        password = ""
    }

    private static func persistPassword(_ value: String) {
        if value.isEmpty {
            KeychainStore.delete(account: KeychainAccounts.password)
        } else {
            KeychainStore.set(value, account: KeychainAccounts.password)
        }
    }

    private static func persistAccessToken(_ value: String?) {
        if let value, !value.isEmpty {
            KeychainStore.set(value, account: KeychainAccounts.accessToken)
        } else {
            KeychainStore.delete(account: KeychainAccounts.accessToken)
        }
    }

    private func persistPassword(_ value: String) {
        Self.persistPassword(value)
    }

    private func persistAccessToken(_ value: String?) {
        Self.persistAccessToken(value)
    }
}
