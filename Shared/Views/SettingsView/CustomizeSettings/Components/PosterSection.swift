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

extension CustomizeSettingsView {

    struct PosterSection: View {

        enum PreviewItemState: CaseIterable, Displayable {
            case inProgress
            case rewatching
            case played
            case unplayed

            var displayTitle: String {
                switch self {
                case .inProgress:
                    L10n.inProgress
                case .rewatching:
                    L10n.rewatching
                case .played:
                    L10n.played
                case .unplayed:
                    L10n.unplayed
                }
            }
        }

        @Default(.Customization.Poster.configuration)
        private var posterConfiguration

        @State
        private var previewItemType: BaseItemKind = .episode

        @State
        private var previewItemState: PreviewItemState = .inProgress

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
            item.type = previewItemType
            item.name = previewItemType == .episode ? L10n.subtitle : previewItemType.displayTitle
            item.indexNumber = previewItemType == .episode ? 3 : nil
            item.parentIndexNumber = previewItemType == .episode ? 1 : nil
            item.extraType = previewItemType == .video ? .trailer : nil
            item.productionYear = 2024
            item.officialRating = "PG-13"
            item.communityRating = 8.2
            item.criticRating = 92
            item.genres = [L10n.genre]
            item.studios = [.init(name: L10n.preview)]
            item.mediaStreams = [.init(height: 2160, type: .video, videoRangeType: .hdr10, width: 3840)]

            let isInProgress = previewItemState == .inProgress || previewItemState == .rewatching
            item.userData?.isPlayed = previewItemState == .played || previewItemState == .rewatching
            item.userData?.playbackPositionTicks = isInProgress ? Duration.seconds(600).ticks : 0
            item.userData?.playedPercentage = isInProgress ? 100 / 3 : 0

            return item
        }

        private var itemTypePicker: some View {
            Picker(L10n.type, selection: $previewItemType) {
                ForEach([BaseItemKind.movie, .series, .season, .episode, .musicVideo, .video], id: \.self) { type in
                    Text(type.displayTitle).tag(type)
                }
            }
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
                        posterDisplayType: type
                    )
                }
                .posterCornerRadius(type)

                previewItem.posterLabel
                    .environment(\.posterDisplayType, type)
            }
            .frame(width: (UIDevice.isTV ? 225 : 150) * (type == .landscape ? 1.77 : 1))
            .posterAccessibility(for: previewItem)
            .animation(.linear(duration: 0.1), value: posterConfiguration)
            .animation(.linear(duration: 0.1), value: previewItemState)
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

                    #if os(tvOS)
                    ListRowMenu(L10n.type, subtitle: previewItemType.displayTitle) {
                        itemTypePicker
                    }
                    #else
                    itemTypePicker
                    #endif
                }

                Section(L10n.labels) {
                    Toggle(L10n.showPosterTitles, isOn: $posterConfiguration.showTitles)

                    #if os(tvOS)
                    ListRowMenu(L10n.subtitle, selection: $posterConfiguration.subtitleField)
                    #else
                    Picker(L10n.subtitle, selection: $posterConfiguration.subtitleField)
                        .pickerStyle(.menu)
                    #endif
                }

                Section(L10n.indicators) {

                    Toggle(L10n.favorited, isOn: $posterConfiguration.indicators.contains(.favorited))

                    Toggle(L10n.progress, isOn: $posterConfiguration.indicators.contains(.progress))

                    Toggle(L10n.played, isOn: $posterConfiguration.indicators.contains(.played))

                    PlatformPicker(
                        L10n.unplayed,
                        selection: Binding {
                            posterConfiguration.indicators.contains(.unplayed) ? posterConfiguration.unplayedStyle : .none
                        } set: { newValue in
                            switch newValue {
                            case .none:
                                posterConfiguration.indicators.remove(.unplayed)
                            case .indicator, .count:
                                posterConfiguration.indicators.insert(.unplayed)
                                posterConfiguration.unplayedStyle = newValue
                            }
                        }
                    )
                }

                Section {
                    Toggle(L10n.useSeriesThumb, isOn: $posterConfiguration.useSeriesLandscapeBackdrop)
                } header: {
                    Text(L10n.episode)
                }
            } image: {
                CenteredLazyVGrid(
                    data: [.portrait, .square, .landscape],
                    id: \.self,
                    columns: 2,
                    spacing: EdgeInsets.itemSpacing
                ) { type in
                    posterPreview(type: type)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .environment(\.posterConfiguration, posterConfiguration)
            .navigationTitle(L10n.posters)
        }
    }
}
