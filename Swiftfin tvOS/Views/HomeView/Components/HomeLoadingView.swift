//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension HomeView {

    struct LoadingView: View {

        private var title: String
        private var cinematic: Bool
        private var posterType: PosterDisplayType = .portrait

        private let elements: [BaseItemDto]

        // MARK: - Initializer

        init(
            title: String,
            cinematic: Bool = false,
            posterType: PosterDisplayType = .portrait
        ) {
            self.title = title
            self.cinematic = cinematic
            self.posterType = posterType

            let tempItem = BaseItemDto(name: "")

            self.elements = [tempItem, tempItem, tempItem]
        }

        // MARK: - Cinematic Image Source

        private func cinematicImageSource(for item: BaseItemDto) -> ImageSource {
            if item.type == .episode {
                return item.seriesImageSource(
                    .logo,
                    maxWidth: 800,
                    maxHeight: 200
                )
            } else {
                return item.imageSource(
                    .logo,
                    maxWidth: 800,
                    maxHeight: 200
                )
            }
        }

        // MARK: - Body

        @ViewBuilder
        var body: some View {
            switch cinematic {
            case false:
                standardView
            case true:
                cinematicView
            }
        }

        // MARK: - Standard View

        var standardView: some View {
            PosterHStack(
                title: title,
                type: posterType,
                items: elements
            )
            .imageOverlay { _ in
                EmptyView()
            }
        }

        // MARK: - Cinematic View

        var cinematicView: some View {
            CinematicItemSelector(
                items: elements,
                type: posterType
            )
            .topContent { item in
                ImageView(cinematicImageSource(for: item))
                    .placeholder { _ in
                        EmptyView()
                    }
                    .edgePadding(.leading)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200, alignment: .bottomLeading)
            }
        }
    }
}
