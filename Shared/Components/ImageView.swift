//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import Nuke
import NukeUI
import SwiftUI

// TODO: currently SVGs are only supported for logos, which are only used in a few places.
//       make it so when displaying an SVG there is a unified `image` caller modifier
// TODO: look at replacing view phase resolution with `FadeContentTransitionView`
// TODO: Allow failure to reserve previous state, keeping placeholder if image fails
struct ImageView<_Image: View, Placeholder: View, Failure: View>: View {

    @State
    private var sources: [ImageSource]

    private var image: (UIImage) -> _Image
    private var pipeline: ImagePipeline
    private var placeholder: (ImageSource) -> Placeholder
    private var failure: Failure

    var body: some View {
        if let currentSource = sources.first {
            LazyImage(url: currentSource.url, transaction: .init(animation: .linear)) { state in
                if state.isLoading {
                    placeholder(currentSource)
                } else if let container = state.imageContainer {
                    if let data = container.data {
                        FastSVGView(data: data)
                    } else {
                        image(container.image)
                    }
                } else if state.error != nil {
                    failure
                        .onAppear {
                            sources.removeFirstSafe()
                        }
                }
            }
            .pipeline(pipeline)
            .onDisappear(.lowerPriority)
        } else {
            failure
        }
    }
}

extension ImageView where _Image == Image, Placeholder == DefaultPlaceholderView, Failure == EmptyView {

    init(_ source: ImageSource) {
        self.init([source].compacted(using: \.url))
    }

    init(_ sources: [ImageSource]) {
        self.init(
            sources: sources.compacted(using: \.url),
            image: { Image(uiImage: $0).resizable() },
            pipeline: .shared,
            placeholder: { DefaultPlaceholderView(blurHash: $0.blurHash) },
            failure: EmptyView()
        )
    }

    init(_ source: URL?) {
        self.init([ImageSource(url: source)])
    }

    init(_ sources: [URL?]) {
        let imageSources = sources
            .compacted()
            .map { ImageSource(url: $0) }

        self.init(imageSources)
    }
}

// MARK: Modifiers

extension ImageView {

    func image<NewImage: View>(
        @ViewBuilder _ content: @escaping (UIImage) -> NewImage
    ) -> ImageView<NewImage, Placeholder, Failure> {
        ImageView<NewImage, Placeholder, Failure>(
            sources: sources,
            image: content,
            pipeline: pipeline,
            placeholder: placeholder,
            failure: failure
        )
    }

    func image<NewImage: View>(
        @ViewBuilder _ content: @escaping (Image) -> NewImage
    ) -> ImageView<NewImage, Placeholder, Failure> {
        ImageView<NewImage, Placeholder, Failure>(
            sources: sources,
            image: { content(Image(uiImage: $0).resizable()) },
            pipeline: pipeline,
            placeholder: placeholder,
            failure: failure
        )
    }

    func pipeline(_ pipeline: ImagePipeline) -> Self {
        copy(modifying: \.pipeline, with: pipeline)
    }

    func placeholder<NewPlaceholder: View>(
        @ViewBuilder _ content: @escaping (ImageSource) -> NewPlaceholder
    ) -> ImageView<_Image, NewPlaceholder, Failure> {
        ImageView<_Image, NewPlaceholder, Failure>(
            sources: sources,
            image: image,
            pipeline: pipeline,
            placeholder: content,
            failure: failure
        )
    }

    func failure<NewFailure: View>(
        @ViewBuilder _ content: @escaping () -> NewFailure
    ) -> ImageView<_Image, Placeholder, NewFailure> {
        ImageView<_Image, Placeholder, NewFailure>(
            sources: sources,
            image: image,
            pipeline: pipeline,
            placeholder: placeholder,
            failure: content()
        )
    }
}

// MARK: Defaults

struct DefaultPlaceholderView: View {

    let blurHash: String?

    var body: some View {
        if let blurHash {
            Image(
                blurHash: blurHash,
                size: .init(width: 8, height: 8)
            )?
                .resizable()
        }
    }
}
