//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import Nuke
import SwiftUI

/// Retrieving images by exact pixel dimensions is a bit
/// intense for normal usage and eases cache usage and modifications.
private let landscapeMaxWidth: CGFloat = 300
private let portraitMaxWidth: CGFloat = 200

struct PosterImage<Item: Poster>: View {

    @ForTypeInEnvironment<Item, (Any) -> PosterStyleEnvironment>(\.posterStyleRegistry)
    private var posterStyleRegistry

    private let contentMode: ContentMode
    private let environment: Item.Environment
    private let imageMaxWidth: CGFloat
    private let item: Item
    private var pipeline: ImagePipeline
    private let type: PosterDisplayType

    private var posterStyle: PosterStyleEnvironment {
        posterStyleRegistry?(item) ?? .default
    }

    private var imageSources: [ImageSource] {
        item.imageSources(
            for: type,
            size: posterStyle.size,
            useParent: posterStyle.useParentImages,
            environment: environment
        )
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
//                        } else if item.showTitle {
                        } else {
                            SystemImageContentView(
                                systemName: item.systemImage
                            )
//                        } else {
//                            SystemImageContentView(
//                                title: item.displayTitle,
//                                systemName: item.systemImage
//                            )
                        }
                    }
                    .failure {
//                        if item.showTitle {
                        SystemImageContentView(
                            systemName: item.systemImage
                        )
//                        } else {
//                            SystemImageContentView(
//                                title: item.displayTitle,
//                                systemName: item.systemImage
//                            )
//                        }
                    }
            }
        }
        .posterStyle(
            type,
            contentMode: contentMode
        )
    }
}

extension PosterImage where Item.Environment == Void {

    init(
        item: Item,
        type: PosterDisplayType,
        contentMode: ContentMode = .fill,
        maxWidth: CGFloat? = nil
    ) {
        self.contentMode = contentMode
        self.environment = ()
        self.imageMaxWidth = maxWidth ?? (type == .landscape ? landscapeMaxWidth : portraitMaxWidth)
        self.item = item
        self.pipeline = .shared
        self.type = type
    }
}

extension PosterImage {

    init(
        item: Item,
        type: PosterDisplayType,
        environment: Item.Environment,
        contentMode: ContentMode = .fill,
        maxWidth: CGFloat? = nil
    ) {
        self.contentMode = contentMode
        self.environment = environment
        self.imageMaxWidth = maxWidth ?? (type == .landscape ? landscapeMaxWidth : portraitMaxWidth)
        self.item = item
        self.pipeline = .shared
        self.type = type
    }
}

extension PosterImage {

    func pipeline(_ pipeline: ImagePipeline) -> Self {
        copy(modifying: \.pipeline, with: pipeline)
    }
}
