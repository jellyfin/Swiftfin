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

extension CustomizeViewsSettings {

    struct PosterSection: View {

        enum PreviewItemState: CaseIterable, Displayable {
            case inProgress
            case played
            case unplayed

            var displayTitle: String {
                switch self {
                case .inProgress:
                    L10n.inProgress
                case .played:
                    L10n.played
                case .unplayed:
                    L10n.unplayed
                }
            }
        }

        @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
        private var useSeriesLandscapeBackdrop

        @Default(.Customization.Indicators.enabled)
        private var indicators

        @State
        private var previewItemState: PreviewItemState = .unplayed

        private let sampleItem: BaseItemDto = .init(
            runTimeTicks: Duration.seconds(1800).ticks,
            type: .movie,
            userData: .init(
                isFavorite: true,
                isPlayed: true,
                playbackPositionTicks: Duration.seconds(600).ticks
            )
        )

        private var previewItem: BaseItemDto {
            var item = sampleItem

            item.userData?.isPlayed = previewItemState == .played
            item.userData?.playbackPositionTicks = previewItemState == .inProgress ? Duration.seconds(600).ticks : 0

            return item
        }

        @ViewBuilder
        private func posterPreview(type: PosterDisplayType) -> some View {
            VStack(alignment: .leading) {
                PosterImage(
                    item: previewItem,
                    type: type,
                    contentMode: .fit
                )
                .overlay {
                    PosterIndicatorsOverlay(
                        item: previewItem,
                        indicators: indicators,
                        posterDisplayType: type
                    )
                }
                .posterCornerRadius(type)

                VStack(alignment: .leading, spacing: 0) {
                    Text(L10n.preview)
                        .font(.footnote)
                        .foregroundStyle(.primary)

                    Text(L10n.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .animation(.linear(duration: 0.1), value: indicators)
            .animation(.linear(duration: 0.1), value: previewItemState)
        }

        var body: some View {
            Form(systemImage: "gear") {
                #if os(iOS)
                Section(L10n.preview) {
                    ScrollView(.horizontal) {
                        HStack(alignment: .bottom) {
                            posterPreview(type: .portrait)
                                .frame(width: 150)

                            posterPreview(type: .landscape)
                                .frame(width: 200)

                            posterPreview(type: .square)
                                .frame(width: 150)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                    .scrollIndicators(.hidden)

                    Picker(L10n.status, selection: $previewItemState)
                }
                #endif

                Section(L10n.indicators) {

                    Toggle(L10n.favorited, isOn: $indicators.contains(.favorited))

                    Toggle(L10n.progress, isOn: $indicators.contains(.progress))

                    Toggle(L10n.played, isOn: $indicators.contains(.played))

                    Toggle(L10n.unplayed, isOn: $indicators.contains(.unplayed))
                }

                Section {
                    Toggle(L10n.useSeriesThumb, isOn: $useSeriesLandscapeBackdrop)
                } header: {
                    Text(L10n.episode)
                }
            }
            .navigationTitle(L10n.posters)
        }
    }
}
