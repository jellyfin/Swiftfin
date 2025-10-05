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

        @Default(.Customization.showPosterLabels)
        private var showPosterLabels

        @Default(.Customization.Indicators.showFavorited)
        private var showFavorited
        @Default(.Customization.Indicators.showProgress)
        private var showProgress
        @Default(.Customization.Indicators.showUnplayed)
        private var showUnplayed
        @Default(.Customization.Indicators.showPlayed)
        private var showPlayed

        @ViewBuilder
        private func posterPreview(type: PosterDisplayType) -> some View {
            VStack(alignment: .leading) {
                PosterImage(
                    item: ExamplePosterItem(),
                    type: type,
                    contentMode: .fit
                )
                .overlay {
                    if showFavorited {
                        FavoriteIndicator()
                    }

                    if showProgress {}

                    if showUnplayed {}

                    if showPlayed {}
                }

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
                }

                Toggle(L10n.showPosterLabels, isOn: $showPosterLabels)

                Section(L10n.indicators) {
                    Toggle(L10n.progress, isOn: $showProgress)

                    Toggle(L10n.unplayed, isOn: $showUnplayed)

                    Toggle(L10n.played, isOn: $showPlayed)
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

    func transform(image: Image) -> some View {
        image
    }
}
