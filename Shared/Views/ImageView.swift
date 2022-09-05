//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import Nuke
import NukeUI
import SwiftUI
import UIKit

struct ImageSource: Hashable {
    let url: URL?
    let blurHash: String?

    init(url: URL? = nil, blurHash: String? = nil) {
        self.url = url
        self.blurHash = blurHash
    }
}

struct DefaultFailureView: View {

    var body: some View {
        Color.secondary
    }
}

struct ImageView<ImageType: View, PlaceholderView: View, FailureView: View>: View {

    @State
    private var sources: [ImageSource]
    private var image: (NukeUI.Image) -> ImageType
    private var placeholder: (() -> PlaceholderView)?
    private var failure: () -> FailureView
    private var resizingMode: ImageResizingMode

    private init(
        _ sources: [ImageSource],
        resizingMode: ImageResizingMode,
        @ViewBuilder image: @escaping (NukeUI.Image) -> ImageType,
        placeHolder: (() -> PlaceholderView)?,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        _sources = State(initialValue: sources)
        self.resizingMode = resizingMode
        self.image = image
        self.placeholder = placeHolder
        self.failure = failureView
    }

    @ViewBuilder
    private func _placeholder(_ currentSource: ImageSource) -> some View {
        if let placeholder = placeholder {
            placeholder()
        } else if let blurHash = currentSource.blurHash {
            BlurHashView(blurHash: blurHash, size: .Circle(radius: 16))
        } else {
            Color.secondarySystemFill
                .opacity(0.5)
        }
    }

    var body: some View {
        if let currentSource = sources.first {
            LazyImage(url: currentSource.url) { state in
                if state.isLoading {
                    _placeholder(currentSource)
                } else if let _image = state.image {
                    image(_image.resizingMode(resizingMode))
                } else if state.error != nil {
                    failure().onAppear {
                        sources.removeFirst()
                    }
                }
            }
            .pipeline(ImagePipeline(configuration: .withDataCache))
            .id(currentSource)
        } else {
            failure()
        }
    }
}

extension ImageView where ImageType == NukeUI.Image, PlaceholderView == EmptyView, FailureView == DefaultFailureView {
    init(_ source: ImageSource) {
        self.init(
            [source],
            resizingMode: .aspectFill,
            image: { $0 },
            placeHolder: nil,
            failureView: { DefaultFailureView() }
        )
    }

    init(_ sources: [ImageSource]) {
        self.init(
            sources,
            resizingMode: .aspectFill,
            image: { $0 },
            placeHolder: nil,
            failureView: { DefaultFailureView() }
        )
    }

    init(_ source: URL?) {
        self.init(
            [ImageSource(url: source, blurHash: nil)],
            resizingMode: .aspectFill,
            image: { $0 },
            placeHolder: nil,
            failureView: { DefaultFailureView() }
        )
    }

    init(_ sources: [URL?]) {
        self.init(
            sources.map { ImageSource(url: $0, blurHash: nil) },
            resizingMode: .aspectFill,
            image: { $0 },
            placeHolder: nil,
            failureView: { DefaultFailureView() }
        )
    }
}

// MARK: Extensions

extension ImageView {
    @ViewBuilder
    func image<I: View>(@ViewBuilder _ content: @escaping (NukeUI.Image) -> I) -> ImageView<I, PlaceholderView, FailureView> {
        ImageView<I, PlaceholderView, FailureView>(
            sources,
            resizingMode: resizingMode,
            image: content,
            placeHolder: placeholder,
            failureView: failure
        )
    }

    @ViewBuilder
    func placeholder<P: View>(@ViewBuilder _ content: @escaping () -> P) -> ImageView<ImageType, P, FailureView> {
        ImageView<ImageType, P, FailureView>(
            sources,
            resizingMode: resizingMode,
            image: image,
            placeHolder: content,
            failureView: failure
        )
    }

    @ViewBuilder
    func failure<F: View>(@ViewBuilder _ content: @escaping () -> F) -> ImageView<ImageType, PlaceholderView, F> {
        ImageView<ImageType, PlaceholderView, F>(
            sources,
            resizingMode: resizingMode,
            image: image,
            placeHolder: placeholder,
            failureView: content
        )
    }

    @ViewBuilder
    func resizingMode(_ resizingMode: ImageResizingMode) -> ImageView<ImageType, PlaceholderView, FailureView> {
        ImageView<ImageType, PlaceholderView, FailureView>(
            sources,
            resizingMode: resizingMode,
            image: image,
            placeHolder: placeholder,
            failureView: failure
        )
    }
}
