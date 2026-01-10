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

#if os(iOS)
private let landscapeMaxWidth: CGFloat = 200
private let portraitMaxWidth: CGFloat = 120
#else
private let landscapeMaxWidth: CGFloat = 500
private let portraitMaxWidth: CGFloat = 500
#endif

struct PosterImage<Element: Poster>: View {

    @Environment(\.viewContext)
    private var viewContext

    @ForTypeInEnvironment<Element, (Any) -> any WithDefaultValue>(\.customEnvironmentValueRegistry)
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
        if var environment = customEnvironmentValue as? WithViewContext {
            environment.viewContext = viewContext
            return element.imageSources(
                for: type,
                size: size,
                environment: environment as! Element.Environment
            )
        } else {
            return element.imageSources(
                for: type,
                size: size,
                environment: customEnvironmentValue
            )
        }
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
                    .placeholder { imageSource in
                        if let blurHash = imageSource.blurHash {
                            BlurHashView(blurHash: blurHash)
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
