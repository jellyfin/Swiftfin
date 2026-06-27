//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import SwiftUI

/// Retrieving images by exact pixel dimensions is a bit
/// intense for normal usage and eases cache usage and modifications.
///
/// tvOS reports a screen scale of 1.0 (unlike Retina iOS, which scales these
/// up 2–3×), so it would otherwise fetch these literal small widths and upscale
/// them onto large 4K posters — appearing blurry. Request larger widths on tvOS.
#if os(tvOS)
private let landscapeMaxWidth: CGFloat = 850
private let portraitMaxWidth: CGFloat = 600
#else
private let landscapeMaxWidth: CGFloat = 300
private let portraitMaxWidth: CGFloat = 200
#endif

struct PosterImage<Item: Poster>: View {

    private let contentMode: ContentMode
    private let imageMaxWidth: CGFloat
    private let item: Item
    private let type: PosterDisplayType

    init(
        item: Item,
        type: PosterDisplayType,
        contentMode: ContentMode = .fill,
        maxWidth: CGFloat? = nil
    ) {
        self.contentMode = contentMode
        self.imageMaxWidth = maxWidth ?? (type == .landscape ? landscapeMaxWidth : portraitMaxWidth)
        self.item = item
        self.type = type
    }

    private var imageSources: [ImageSource] {
        switch type {
        case .landscape:
            item.landscapeImageSources(maxWidth: imageMaxWidth, quality: 90)
        case .portrait:
            item.portraitImageSources(maxWidth: imageMaxWidth, quality: 90)
        case .square:
            item.squareImageSources(maxWidth: imageMaxWidth, quality: 90)
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.complexSecondary)

            AlternateLayoutView {
                Color.clear
            } content: {
                ImageView(imageSources)
                    .image(item.transform)
                    .placeholder { imageSource in
                        if let blurHash = imageSource.blurHash {
                            BlurHashView(blurHash: blurHash)
                        } else if item.showTitle {
                            SystemImageContentView(
                                systemName: item.systemImage
                            )
                        } else {
                            SystemImageContentView(
                                title: item.displayTitle,
                                systemName: item.systemImage
                            )
                        }
                    }
                    .failure {
                        if item.showTitle {
                            SystemImageContentView(
                                systemName: item.systemImage
                            )
                        } else {
                            SystemImageContentView(
                                title: item.displayTitle,
                                systemName: item.systemImage
                            )
                        }
                    }
            }
        }
        .posterStyle(
            type,
            contentMode: contentMode
        )
    }
}
