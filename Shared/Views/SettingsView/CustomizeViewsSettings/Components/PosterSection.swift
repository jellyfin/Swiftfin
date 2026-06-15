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

        @Default(.Customization.Indicators.showFavorited)
        private var showFavorited
        @Default(.Customization.Indicators.showProgress)
        private var showProgress
        @Default(.Customization.Indicators.showUnplayed)
        private var showUnplayed
        @Default(.Customization.Indicators.showPlayed)
        private var showPlayed

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
                .posterCornerRadius(type)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Example")
                        .font(.footnote)
                        .foregroundStyle(.primary)

                    Text("Subtitle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .animation(.linear(duration: 0.1), value: showFavorited)
            .animation(.linear(duration: 0.1), value: showProgress)
            .animation(.linear(duration: 0.1), value: showUnplayed)
            .animation(.linear(duration: 0.1), value: showPlayed)
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

                    Toggle(L10n.favorited, isOn: $showFavorited)

                    Toggle(L10n.progress, isOn: $showProgress)

                    Toggle(L10n.played, isOn: $showPlayed)

                    Picker(L10n.unplayed, selection: $showUnplayed)
                }

                Section {
                    Toggle("Series backdrop", isOn: $useSeriesLandscapeBackdrop)
                } header: {
                    // TODO: think of a better name
                    Text("Episode landscape poster")
                }
            }
            .navigationTitle(L10n.posters)
        }
    }
}
