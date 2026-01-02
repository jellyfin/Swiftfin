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

/// Retrieving images by exact pixel dimensions is a bit
/// intense for normal usage and eases cache usage and modifications.
#if os(iOS)
private let landscapeMaxWidth: CGFloat = 200
private let portraitMaxWidth: CGFloat = 120
#else
private let landscapeMaxWidth: CGFloat = 500
private let portraitMaxWidth: CGFloat = 500
#endif

struct PosterImage<Element: Poster>: View {

    @ForTypeInEnvironment<Element, (Any) -> any CustomEnvironmentValue>(\.customEnvironmentValueRegistry)
    private var customEnvironmentValueRegistry

    private let contentMode: ContentMode
    private let element: Element
    // TODO: figure out what to do with this
    private let imageMaxWidth: CGFloat
    private var pipeline: ImagePipeline
    private let size: PosterDisplayType.Size
    private let type: PosterDisplayType

    private var customEnvironmentValue: Element.Environment {
        (customEnvironmentValueRegistry?(element) as? Element.Environment) ?? .default
    }

    private var imageSources: [ImageSource] {
        element.imageSources(
            for: type,
            size: size,
            environment: customEnvironmentValue
        )
    }

    init(
        item: Element,
        type: PosterDisplayType,
        contentMode: ContentMode = .fill,
        maxWidth: CGFloat? = nil,
        size: PosterDisplayType.Size = .small
    ) {
        self.contentMode = contentMode
        self.element = item
        self.imageMaxWidth = maxWidth ?? (type == .landscape ? landscapeMaxWidth : portraitMaxWidth)
        self.pipeline = .shared
        self.size = size
        self.type = type
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.complexSecondary)

            AlternateLayoutView {
                Color.clear
            } content: {
                ImageView(imageSources)
                    .image { image in
                        element.transform(image: image, displayType: type)
                    }
//                    .image(element.transform)
                    .placeholder { imageSource in
                        if let blurHash = imageSource.blurHash {
                            BlurHashView(blurHash: blurHash)
//                        } else if item.showTitle {
                        } else {
                            SystemImageContentView(
                                systemName: element.systemImage
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
                            systemName: element.systemImage
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

extension PosterImage {

    func pipeline(_ pipeline: ImagePipeline) -> Self {
        copy(modifying: \.pipeline, with: pipeline)
    }
}
