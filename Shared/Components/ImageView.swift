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
// TODO: `LazyImage` uses a transaction for view swapping, which will fade out old views
//       and fade in new views, causing a black "flash" between the placeholder and final image.
//       Since we use blur hashes, we actually just want the final image to fade in on top while
//       the blur hash view is at full opacity.
//       - refactor for option
//       - take a look at `RotateContentView`
struct ImageView<_Image: View, Placeholder: View, Failure: View>: View {

    @State
    private var sources: [ImageSource]

    private let failure: Failure
    private let image: (Image) -> _Image
    private var pipeline: ImagePipeline
    private let placeholder: (ImageSource) -> Placeholder

    var body: some View {
        if let currentSource = sources.first {
            LazyImage(url: currentSource.url, transaction: .init(animation: .linear)) { state in
                if state.isLoading {
                    placeholder(currentSource)
                } else if let _image = state.image {
                    if let data = state.imageContainer?.data {
                        FastSVGView(data: data)
                    } else {
                        image(_image.resizable())
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
            failure: EmptyView(),
            image: { $0 },
            pipeline: .shared,
            placeholder: { DefaultPlaceholderView(blurHash: $0.blurHash) }
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

    func failure<F: View>(
        @ViewBuilder _ content: @escaping () -> F
    ) -> ImageView<_Image, Placeholder, F> {
        ImageView<_Image, Placeholder, F>(
            sources: sources,
            failure: content(),
            image: image,
            pipeline: pipeline,
            placeholder: placeholder
        )
    }

    func image<I: View>(
        @ViewBuilder _ content: @escaping (Image) -> I
    ) -> ImageView<I, Placeholder, Failure> {
        ImageView<I, Placeholder, Failure>(
            sources: sources,
            failure: failure,
            image: content,
            pipeline: pipeline,
            placeholder: placeholder
        )
    }

    func pipeline(_ pipeline: ImagePipeline) -> Self {
        copy(modifying: \.pipeline, with: pipeline)
    }

    func placeholder<P: View>(
        @ViewBuilder _ content: @escaping (ImageSource) -> P
    ) -> ImageView<_Image, P, Failure> {
        ImageView<_Image, P, Failure>(
            sources: sources,
            failure: failure,
            image: image,
            pipeline: pipeline,
            placeholder: content
        )
    }
}

// MARK: Defaults

struct DefaultPlaceholderView: View {

    let blurHash: String?

    var body: some View {
        if let blurHash {
            BlurHashView(blurHash: blurHash, size: .Square(length: 8))
        }
    }
}
