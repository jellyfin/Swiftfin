//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

extension CustomDeviceProfileSettingsView {
    struct CustomProfileButton: View {
        let profile: CustomDeviceProfile
        var onSelect: () -> Void

        @ViewBuilder
        private func profileDetailsView(title: String, detail: String) -> some View {
            VStack(alignment: .leading) {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(detail)
                    .foregroundColor(.secondary)
            }
            .font(.subheadline)
        }

        var body: some View {
            Button(action: onSelect) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        profileDetailsView(
                            title: L10n.audio,
                            detail: profile.audio.map(\.displayTitle).joined(separator: ", ")
                        )

                        profileDetailsView(
                            title: L10n.video,
                            detail: profile.video.map(\.displayTitle).joined(separator: ", ")
                        )

                        profileDetailsView(
                            title: L10n.containers,
                            detail: profile.container.map(\.displayTitle).joined(separator: ", ")
                        )

                        profileDetailsView(
                            title: L10n.useAsTranscodingProfile,
                            detail: profile.useAsTranscodingProfile ? L10n.yes : L10n.no
                        )
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.body.weight(.regular))
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
    }
}
