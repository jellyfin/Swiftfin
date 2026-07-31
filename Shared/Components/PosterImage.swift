//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import Nuke
import SwiftUI

struct PosterImage<Element: Poster>: View {

    @Environment(\.self)
    private var environment

    private let contentMode: ContentMode
    private let element: Element
    private var pipeline: ImagePipeline
    private let size: PosterDisplayType.Size
    private let displayType: PosterDisplayType

    init(
        item: Element,
        type: PosterDisplayType,
        size: PosterDisplayType.Size = .small,
        contentMode: ContentMode = .fill
    ) {
        self.contentMode = contentMode
        self.displayType = type
        self.element = item
        self.pipeline = .shared
        self.size = size
    }

    private var imageSources: [ImageSource] {
        element.imageSources(
            for: displayType,
            size: size,
            environment: element.resolveEnvironment(environment)
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
                    .pipeline(pipeline)
                    .image { image in
                        element.transform(image: image, displayType: displayType)
                    }
                    .placeholder { imageSource in
                        if let blurHash = imageSource.blurHash {
                            Image(
                                blurHash: blurHash,
                                size: .init(width: 8, height: 8)
                            )?
                                .resizable()
                        } else {
                            SystemImageContentView(
                                systemName: element.systemImage
                            )
                        }
                    }
                    .failure {
                        SystemImageContentView(
                            systemName: element.systemImage
                        )
                    }
                    .accessibilityRemoveTraits(.isImage)
                    .accessibilityIgnoresInvertColors()
            }
        }
        .posterStyle(
            displayType,
            contentMode: contentMode
        )
    }
}

extension PosterImage {

    func pipeline(_ pipeline: ImagePipeline) -> Self {
        copy(modifying: \.pipeline, with: pipeline)
    }
}
