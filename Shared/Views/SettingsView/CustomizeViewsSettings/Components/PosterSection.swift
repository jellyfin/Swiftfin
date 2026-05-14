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
                    "In progress"
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

        @ViewBuilder
        private func posterPreview(type: PosterDisplayType) -> some View {
            VStack(alignment: .leading) {
                PosterImage(
                    item: sampleItem,
                    type: type,
                    contentMode: .fit
                )
                .overlay {
                    PosterIndicatorsOverlay(
                        item: sampleItem,
                        indicators: indicators
                            .removing(.progress, if: previewItemState != .inProgress)
                            .removing(.played, if: previewItemState != .played)
                            .removing(.unplayed, if: previewItemState != .unplayed),
                        posterDisplayType: type
                    )
                }
                .posterCornerRadius(type)

                TitleSubtitleContentView(
                    title: "Example",
                    subtitle: "Subtitle"
                )
            }
            .animation(.linear(duration: 0.1), value: indicators)
            .animation(.linear(duration: 0.1), value: previewItemState)
        }

        var body: some View {
            Form {
                #if os(iOS)
                Section("Preview") {
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

                    Picker("Status", selection: $previewItemState)
                }
                #endif

                Section(L10n.indicators) {

                    Toggle(L10n.favorited, isOn: $indicators.contains(.favorited))

                    Toggle(L10n.progress, isOn: $indicators.contains(.progress))

                    Toggle(L10n.played, isOn: $indicators.contains(.played))

                    Toggle(L10n.unplayed, isOn: $indicators.contains(.unplayed))
                }

                Section {
                    Toggle("Series backdrop", isOn: $useSeriesLandscapeBackdrop)
                } header: {
                    // TODO: think of a better name
                    Text("Episode landscape poster")
                }
            } image: {
                Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .navigationTitle(L10n.posters)
        }
    }
}
