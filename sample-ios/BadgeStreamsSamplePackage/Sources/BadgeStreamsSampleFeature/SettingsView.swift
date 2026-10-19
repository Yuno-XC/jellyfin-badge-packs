import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    var onSignedIn: () -> Void

    @State private var isSigningIn = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var showCredentialEditor = false

    var body: some View {
        Form {
            Section {
                TextField("Jellyfin URL (AIOM or AIOS)", text: $settings.serverURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                if settings.hasStoredCredentials && !showCredentialEditor {
                    LabeledContent("Login") {
                        Text("Saved — stays signed in")
                            .foregroundStyle(.secondary)
                    }
                    if settings.isSignedIn {
                        LabeledContent("Status") {
                            Text("Signed in")
                                .foregroundStyle(.green)
                        }
                    }
                    Button("Change account…") {
                        showCredentialEditor = true
                    }
                } else {
                    TextField("Username", text: $settings.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.username)
                    SecureField("Password", text: $settings.password)
                        .textContentType(.password)

                    Button {
                        Task { await signIn() }
                    } label: {
                        if isSigningIn {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(settings.hasStoredCredentials ? "Save & stay signed in" : "Sign in once")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSigningIn || settings.serverURL.isEmpty || settings.username.isEmpty || settings.password.isEmpty)

                    if showCredentialEditor {
                        Button("Cancel") {
                            showCredentialEditor = false
                        }
                    }
                }
            } header: {
                Text("Jellyfin")
            } footer: {
                Text(settings.hasStoredCredentials
                     ? "Catalogs and playback use this server. Credentials stay in Keychain."
                     : "Enter credentials once. They’re stored in Keychain.")
            }

            Section {
                TextField("AIOS URL (Jellyfin or Stremio)", text: $settings.streamAddonURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
            } header: {
                Text("Badge packs")
            } footer: {
                Text("Point this at the modified AIOS that publishes pack URLs on System/Info. Required when Jellyfin is stock AIOM wrapping AIOS. Leave blank if Jellyfin is AIOS itself.")
            }

            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            guard settings.canAutoSignIn, !settings.isSignedIn else { return }
            await signIn(silent: true)
        }
    }

    private func signIn(silent: Bool = false) async {
        isSigningIn = true
        errorMessage = nil
        if !silent { statusMessage = nil }
        defer { isSigningIn = false }
        do {
            try await SessionAuth.ensureSignedIn(settings: settings)
            showCredentialEditor = false
            statusMessage = silent ? nil : "Staying signed in"
            onSignedIn()
        } catch {
            if !silent {
                errorMessage = error.localizedDescription
            }
        }
    }
}
