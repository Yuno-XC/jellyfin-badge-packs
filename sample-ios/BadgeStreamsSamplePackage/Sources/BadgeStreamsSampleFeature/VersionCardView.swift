import SwiftUI

struct VersionCardView: View {
    let source: JellyfinMediaSource
    let badges: [BadgeRule]
    var packsReady: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(source.displayText)
                .font(.subheadline.monospaced())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !packsReady {
                ProgressView()
                    .controlSize(.mini)
            } else if !badges.isEmpty {
                BadgeLogoRow(badges: badges)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
