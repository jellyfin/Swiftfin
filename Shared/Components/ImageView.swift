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
// TODO: make Image and Placeholder generic constraints rather than any View
struct ImageView<Failure: View>: View {

    @State
    private var sources: [ImageSource]

    private var image: (Image) -> any View
    private var pipeline: ImagePipeline
    private var placeholder: ((ImageSource) -> any View)?
    private var failure: Failure

    @ViewBuilder
    private func _placeholder(_ currentSource: ImageSource) -> some View {
        if let placeholder = placeholder {
            placeholder(currentSource)
                .eraseToAnyView()
        } else {
            DefaultPlaceholderView(blurHash: currentSource.blurHash)
        }
    }

    var body: some View {
        if let currentSource = sources.first {
            LazyImage(url: currentSource.url, transaction: .init(animation: .linear)) { state in
                if state.isLoading {
                    _placeholder(currentSource)
                } else if let _image = state.image {
                    if let data = state.imageContainer?.data {
                        FastSVGView(data: data)
                    } else {
                        image(_image.resizable())
                            .eraseToAnyView()
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

extension ImageView where Failure == EmptyView {

    init(_ source: ImageSource) {
        self.init([source].compacted(using: \.url))
    }

    init(_ sources: [ImageSource]) {
        self.init(
            sources: sources.compacted(using: \.url),
            image: { $0 },
            pipeline: .shared,
            placeholder: nil,
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

    func image(@ViewBuilder _ content: @escaping (Image) -> any View) -> Self {
        copy(modifying: \.image, with: content)
    }

    func pipeline(_ pipeline: ImagePipeline) -> Self {
        copy(modifying: \.pipeline, with: pipeline)
    }

    func placeholder(@ViewBuilder _ content: @escaping (ImageSource) -> any View) -> Self {
        copy(modifying: \.placeholder, with: content)
    }

    func failure<NewFailure: View>(@ViewBuilder _ content: @escaping () -> NewFailure) -> ImageView<NewFailure> {
        ImageView<NewFailure>(
            sources: sources,
            image: image,
            pipeline: pipeline,
            placeholder: placeholder,
            failure: content()
        )
    }
}

// MARK: Defaults

struct DefaultFailureView: View {

    var body: some View {
        Color.secondarySystemFill
            .opacity(0.75)
    }
}

struct DefaultPlaceholderView: View {

    let blurHash: String?

    var body: some View {
        if let blurHash {
            BlurHashView(blurHash: blurHash, size: .Square(length: 8))
        }
    }
}
