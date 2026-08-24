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
        @Default(.Customization.Indicators.unplayedStyle)
        private var unplayedStyle

        @Default(.Customization.showPosterLabels)
        private var showPosterLabels

        @State
        private var previewItemState: PreviewItemState = .unplayed

        private let sampleItem: BaseItemDto = .init(
            name: L10n.subtitle,
            runTimeTicks: Duration.seconds(1800).ticks,
            seriesName: L10n.preview,
            type: .episode,
            userData: .init(
                isFavorite: true,
                isPlayed: true,
                key: "",
                playbackPositionTicks: Duration.seconds(600).ticks,
                unplayedItemCount: 3
            )
        )

        private var previewItem: BaseItemDto {
            var item = sampleItem

            item.userData?.isPlayed = previewItemState == .played
            item.userData?.playbackPositionTicks = previewItemState == .inProgress ? Duration.seconds(600).ticks : 0
            item.userData?.playedPercentage = previewItemState == .inProgress ? 100 / 3 : 0

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

                if showPosterLabels {
                    previewItem.posterLabel
                        .environment(\.posterDisplayType, type)
                }
            }
            .frame(width: (UIDevice.isTV ? 225 : 150) * (type == .landscape ? 1.77 : 1))
            .animation(.linear(duration: 0.1), value: indicators)
            .animation(.linear(duration: 0.1), value: unplayedStyle)
            .animation(.linear(duration: 0.1), value: previewItemState)
            .animation(.linear(duration: 0.1), value: showPosterLabels)
        }

        var body: some View {
            Form {
                Section(L10n.preview) {
                    #if os(iOS)
                    ScrollView(.horizontal) {
                        HStack(alignment: .bottom) {
                            ForEach([PosterDisplayType.portrait, .landscape, .square]) { type in
                                posterPreview(type: type)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                    }
                    .scrollIndicators(.hidden)
                    #endif

                    PlatformPicker(L10n.status, selection: $previewItemState)
                }

                Section(L10n.labels) {
                    Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)
                }

                Section(L10n.indicators) {

                    Toggle(L10n.favorited, isOn: $indicators.contains(.favorited))

                    Toggle(L10n.progress, isOn: $indicators.contains(.progress))

                    Toggle(L10n.played, isOn: $indicators.contains(.played))

                    PlatformPicker(
                        L10n.unplayed,
                        selection: Binding {
                            indicators.contains(.unplayed) ? unplayedStyle : .none
                        } set: { newValue in
                            switch newValue {
                            case .none:
                                indicators.remove(.unplayed)
                            case .indicator, .count:
                                indicators.insert(.unplayed)
                                unplayedStyle = newValue
                            }
                        }
                    )
                }

                Section {
                    Toggle(L10n.useSeriesThumb, isOn: $useSeriesLandscapeBackdrop)
                } header: {
                    Text(L10n.episode)
                }
            } image: {
                CenteredLazyVGrid(
                    data: [.portrait, .square, .landscape],
                    id: \.self,
                    columns: 2,
                    spacing: EdgeInsets.edgePadding
                ) { type in
                    posterPreview(type: type)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .navigationTitle(L10n.posters)
        }
    }
}
