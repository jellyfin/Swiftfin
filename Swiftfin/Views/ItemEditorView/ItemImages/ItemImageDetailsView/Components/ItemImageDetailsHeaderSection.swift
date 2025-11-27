//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemImageDetailsView {

    struct HeaderSection: View {

        // MARK: - Image Info

        let imageSource: ImageSource
        let imageType: ImageType?
        let posterType: PosterDisplayType

        // MARK: - Body

        var body: some View {
            Section {
                PosterImage(
                    item: BasicImagePosterItem(
                        displayTitle: L10n.image,
                        id: 0,
                        imageSource: imageSource,
                        preferredPosterDisplayType: posterType,
                        systemImage: "photo",
                        type: imageType
                    ),
                    type: posterType,
                    contentMode: .fit
                )
                .pipeline(.Swiftfin.other)
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 300)
            .listRowBackground(Color.clear)
            .listRowCornerRadius(0)
            .listRowInsets(.zero)
        }
    }
}

// TODO: have ImageInfo and RemoteImageInfo conform to a shared protocol

private struct BasicImagePosterItem: Poster {

    let displayTitle: String
    let id: Int
    let imageSource: ImageSource
    let preferredPosterDisplayType: PosterDisplayType
    let systemImage: String
    let type: ImageType?

    var unwrappedIDHashOrZero: Int {
        id
    }

    func imageSources(
        for displayType: PosterDisplayType,
        size: PosterDisplayType.Size,
        environment: VoidWithDefaultValue
    ) -> [ImageSource] {
        [imageSource]
    }

    @ViewBuilder
    func transform(image: Image, displayType: PosterDisplayType) -> some View {
        switch type {
        case .logo:
            ContainerRelativeView(ratio: 0.95) {
                image
                    .aspectRatio(contentMode: .fit)
            }
        default:
            image
                .aspectRatio(contentMode: .fill)
        }
    }
}
