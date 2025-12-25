//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
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
                    return "In progress"
                case .played:
                    return L10n.played
                case .unplayed:
                    return L10n.unplayed
                }
            }
        }

        @Default(.Customization.showPosterLabels)
        private var showPosterLabels

        @Default(.Customization.Indicators.showFavorited)
        private var showFavorited

        @Default(.Customization.Episodes.useSeriesLandscapeBackdrop)
        private var useSeriesLandscapeBackdrop

        @Default(.Customization.Indicators.showPlayed)
        private var showPlayed
        @Default(.Customization.Indicators.showProgress)
        private var showProgress
        @Default(.Customization.Indicators.showUnplayed)
        private var showUnplayed

        @State
        private var previewItemState: PreviewItemState = .unplayed

        @ViewBuilder
        private func posterPreview(type: PosterDisplayType) -> some View {
            VStack(alignment: .leading) {
                PosterImage(
                    item: ExamplePosterItem(),
                    type: type,
                    contentMode: .fit
                )
                .overlay {
                    if showProgress, previewItemState == .inProgress {
                        PosterProgressBar(
                            title: Duration.seconds(1800).formatted(.runtime),
                            progress: 0.33,
                            posterDisplayType: type
                        )
                    }

                    if showPlayed, previewItemState == .played {
                        PlayedIndicator()
                    }

                    if showUnplayed, previewItemState == .unplayed {
                        UnplayedIndicator()
                    }
                }
                .posterCornerRadius(type)

                AlternateLayoutView(alignment: .topLeading) {
                    TitleSubtitleContentView(
                        title: "Example",
                        subtitle: "Subtitle"
                    )
                } content: {
                    TitleSubtitleContentView(
                        title: showPosterLabels ? "Example" : nil,
                        subtitle: "Subtitle"
                    )
                }
            }
            .animation(.linear(duration: 0.1), value: showPlayed)
            .animation(.linear(duration: 0.1), value: showProgress)
            .animation(.linear(duration: 0.1), value: showUnplayed)
            .animation(.linear(duration: 0.1), value: previewItemState)
        }

        var body: some View {
            Form {
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

                Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

                Section(L10n.indicators) {
                    Toggle(L10n.progress, isOn: $showProgress)

                    Toggle(L10n.unplayed, isOn: $showUnplayed)

                    Toggle(L10n.played, isOn: $showPlayed)
                }

                Section {
                    Toggle(L10n.seriesBackdrop, isOn: $useSeriesLandscapeBackdrop)
                } header: {
                    // TODO: think of a better name
                    Text(L10n.episodeLandscapePoster)
                }
            }
            .navigationTitle(L10n.posters)
        }
    }
}

struct ExamplePosterItem: Poster {

    let preferredPosterDisplayType: PosterDisplayType = .portrait
    let displayTitle: String = "Example"
    let unwrappedIDHashOrZero: Int = 0
    let systemImage: String = "film"
    let id: String = "example"

//    func transform(image: Image, displayType: PosterDisplayType) -> some View {
//        image
//    }
}
