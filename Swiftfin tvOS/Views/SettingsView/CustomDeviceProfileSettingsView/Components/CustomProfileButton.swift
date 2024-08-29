//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct CustomProfileButton: View {
    let profile: PlaybackDeviceProfile
    let isEditing: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void

    var body: some View {
        Button(action: isEditing ? onDelete : onSelect) {
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
                        detail: profile.useAsTranscodingProfile ? "Yes" : "No"
                    )
                }
                Spacer()
                if isEditing {
                    Image(systemName: "trash.circle.fill")
                        .resizable()
                        .font(.body.weight(.regular))
                        .foregroundColor(.red)
                        .frame(width: 100, height: 100)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.regular))
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private func profileDetailsView(title: String, detail: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .bold()
            Text(detail)
                .foregroundColor(.secondary)
        }
    }
}
