//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension ItemSubtitleSearchView {

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

                        LabeledContent(L10n.language, value: subtitle.threeLetterISOLanguageName ?? L10n.unknown)

                        if let downloadCount = subtitle.downloadCount {
                            LabeledContent(L10n.downloads, value: downloadCount.description)
                        }

                        if let rating = subtitle.communityRating {
                            LabeledContent(L10n.communityRating, value: String(format: "%.1f", rating))
                        }

                        if let author = subtitle.author {
                            LabeledContent(L10n.author, value: author)
                        }

                        if let format = subtitle.format {
                            LabeledContent(L10n.format, value: format)
                        }
                    }
                    .foregroundStyle(isSelected ? .primary : .secondary, .secondary)
                    .font(.caption)

                    Spacer()

                    ListRowCheckbox()
                }
            }
        }
    }
}
