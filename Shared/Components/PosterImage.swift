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

    @Environment(\.viewContext)
    private var viewContext

    private let contentMode: ContentMode
    private let element: Element
    private var pipeline: ImagePipeline
    private let size: PosterDisplayType.Size
    private let type: PosterDisplayType

    init(
        item: Element,
        type: PosterDisplayType,
        contentMode: ContentMode = .fill,
//        maxWidth: CGFloat? = nil,
        size: PosterDisplayType.Size = .small
    ) {
        self.contentMode = contentMode
        self.element = item
        self.pipeline = .shared
//        self.size = maxWidth.map { .custom(width: $0) } ?? size
        self.size = size
        self.type = type
    }

    private var imageSources: [ImageSource] {
        var environment = Element.Environment.default

        if var environmentWithViewContext = environment as? WithViewContext {
            environmentWithViewContext.viewContext = viewContext
            environment = environmentWithViewContext as! Element.Environment
        }

        return element.imageSources(
            for: type,
            size: size,
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
                    .pipeline(pipeline)
                    .image { image in
                        element.transform(image: image, displayType: type)
                    }
                    .placeholder { imageSource in
                        if let blurHash = imageSource.blurHash {
                            Image(
                                blurHash: blurHash,
                                size: .init(width: 8, height: 8)
                            )?
                                .resizable()
                        } else if element.showTitle {
                            SystemImageContentView(
                                systemName: element.systemImage
                            )
                        } else {
                            SystemImageContentView(
                                title: element.displayTitle,
                                systemName: element.systemImage
                            )
                        }
                    }
                    .failure {
                        if element.showTitle {
                            SystemImageContentView(
                                systemName: element.systemImage
                            )
                        } else {
                            SystemImageContentView(
                                title: element.displayTitle,
                                systemName: element.systemImage
                            )
                        }
                    }
                    .accessibilityRemoveTraits(.isImage)
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
