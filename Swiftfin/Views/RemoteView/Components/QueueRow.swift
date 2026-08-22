//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension RemoteView.QueueView {

    struct QueueRow: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected

        let item: BaseItemDto
        let isPaused: Bool
        let action: () -> Void

        @ViewBuilder
        private var leadingView: some View {
            PosterImage(
                item: item,
                type: item.preferredPosterDisplayType,
                contentMode: .fit
            )
            .frame(width: 60)
            .overlay {
                if isSelected {
                    ZStack {
                        Color.black.opacity(0.5)

                        NowPlayingIndicator()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(accentColor)
                            .disabled(isPaused)
                    }
                    .posterStyle(item.preferredPosterDisplayType)
                }
            }
            .subtleShadow()
        }

        @ViewBuilder
        private var trailingView: some View {
            VStack(alignment: .leading, spacing: 4) {
                switch item.type {
                case .episode:
                    if let seriesName = item.seriesName {
                        Text(seriesName)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.displayTitle)
                        .font(.body)

                    if let seasonEpisodeLabel = item.seasonEpisodeLabel {
                        Text(seasonEpisodeLabel)
                            .foregroundStyle(.secondary)
                    }
                case .audio:
                    if let artists = item.artists, artists.isNotEmpty {
                        Text(artists.joined(separator: ", "))
                            .foregroundStyle(.secondary)
                    }

                    Text(item.displayTitle)
                        .font(.body)

                    if let runtime = item.runtime {
                        Text(runtime, format: .runtime)
                            .foregroundStyle(.secondary)
                    }
                case .movie:
                    Text(item.displayTitle)
                        .font(.body)

                    if let premiereDateYear = item.premiereDateYear {
                        Text(premiereDateYear)
                            .foregroundStyle(.secondary)
                    }
                default:
                    Text(item.displayTitle)
                        .font(.body)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .font(.subheadline)
            .lineLimit(1)
        }

        var body: some View {
            ListRow {
                leadingView
            } content: {
                trailingView
            } action: {
                action()
            }
            .listRowBackground(isSelected ? accentColor.opacity(0.2) : nil)
        }
    }
}
