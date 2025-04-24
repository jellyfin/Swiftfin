//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

struct SubtitleResultRow: View {

    // MARK: - Environment Variables

    @Environment(\.isSelected)
    var isSelected

    // MARK: - Subtitle Variable

    let subtitle: RemoteSubtitleInfo

    // MARK: - Subtitle Action

    let onSelect: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(subtitle.name ?? L10n.unknown)
                        .font(.headline)
                        .fontWeight(.semibold)

                    TextPairView(
                        leading: L10n.language,
                        trailing: subtitle.threeLetterISOLanguageName ?? L10n.unknown
                    )
                    .font(.caption)

                    TextPairView(
                        leading: L10n.downloads,
                        trailing: subtitle.downloadCount?.description ?? .emptyDash
                    )
                    .font(.caption)

                    if let rating = subtitle.communityRating {
                        TextPairView(
                            leading: L10n.communityRating,
                            trailing: String(format: "%.1f", rating)
                        )
                        .font(.caption)
                    }

                    TextPairView(
                        leading: L10n.author,
                        trailing: subtitle.author ?? L10n.unknown
                    )
                    .font(.caption)

                    TextPairView(
                        leading: L10n.format,
                        trailing: subtitle.format ?? L10n.unknown
                    )
                    .font(.caption)
                }
                .foregroundStyle(isSelected ? .primary : .secondary, .secondary)

                Spacer()

                ListRowCheckbox()
            }
        }
    }
}
