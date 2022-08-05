//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Nuke
import NukeUI
import SwiftUI
import UIKit

struct ImageSource {
    let url: URL?
    let blurHash: String?

    init(url: URL? = nil, blurHash: String? = nil) {
        self.url = url
        self.blurHash = blurHash
    }
}

struct DefaultImageContentView: View {
    @Binding
    var sources: [ImageSource]
    var state: LazyImageState
    var resizingMode: ImageResizingMode
    var currentBlurHash: String? { sources.first?.blurHash }

    @ViewBuilder
    private var placeholderView: some View {
        if let currentBlurHash = currentBlurHash {
            BlurHashView(blurHash: currentBlurHash)
                .id(currentBlurHash)
        } else {
            Color.clear
        }
    }

    var body: some View {
        if let image = state.image {
            image
                .resizingMode(resizingMode)
        } else if state.error != nil {
            placeholderView.onAppear {
                sources = Array(sources.dropFirst())
            }
        } else {
            placeholderView
        }
    }
}

struct DefaultFailureView: View {
    var body: some View {
        Color.secondary
    }
}

struct ImageView<ContentView: View, FailureView: View>: View {
    @State
    private var sources: [ImageSource]
    private var currentURL: URL? { sources.first?.url }
    private var contentView: (DefaultImageContentView) -> ContentView
    private var failureView: () -> FailureView
    private var resizingMode: ImageResizingMode

    init(
        _ source: URL?,
        blurHash: String? = nil,
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder contentView: @escaping ((DefaultImageContentView) -> ContentView),
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        let imageSource = ImageSource(url: source, blurHash: blurHash)
        self.init(imageSource, resizingMode: resizingMode, contentView: contentView, failureView: failureView)
    }

    init(
        _ source: ImageSource,
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder contentView: @escaping ((DefaultImageContentView) -> ContentView),
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        self.init([source], resizingMode: resizingMode, contentView: contentView, failureView: failureView)
    }

    init(
        _ sources: [ImageSource],
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder contentView: @escaping ((DefaultImageContentView) -> ContentView),
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        _sources = State(initialValue: sources)
        self.resizingMode = resizingMode
        self.contentView = contentView
        self.failureView = failureView
    }

    var body: some View {
        if let currentURL = currentURL {
            LazyImage(source: currentURL) { state in
                contentView(DefaultImageContentView(sources: $sources, state: state, resizingMode: resizingMode))
            }
            .pipeline(ImagePipeline(configuration: .withDataCache))
            .id(currentURL)
        } else {
            failureView()
        }
    }
}

extension ImageView where ContentView == DefaultImageContentView {
    init(
        _ source: URL?,
        blurHash: String? = nil,
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        let imageSource = ImageSource(url: source, blurHash: blurHash)
        self.init([imageSource], resizingMode: resizingMode, contentView: { $0 }, failureView: failureView)
    }

    init(
        _ source: ImageSource,
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        self.init([source], resizingMode: resizingMode, contentView: { $0 }, failureView: failureView)
    }

    init(
        _ sources: [ImageSource],
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        self.init(sources, resizingMode: resizingMode, contentView: { $0 }, failureView: failureView)
    }

    init(
        sources: [URL],
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        let imageSources = sources.compactMap { ImageSource(url: $0, blurHash: nil) }
        self.init(imageSources, resizingMode: resizingMode, contentView: { $0 }, failureView: failureView)
    }
}

extension ImageView where ContentView == DefaultImageContentView, FailureView == DefaultFailureView {
    init(_ source: URL?, blurHash: String? = nil, resizingMode: ImageResizingMode = .aspectFill) {
        let imageSource = ImageSource(url: source, blurHash: blurHash)
        self.init([imageSource], resizingMode: resizingMode, contentView: { $0 }, failureView: { DefaultFailureView() })
    }

    init(_ source: ImageSource, resizingMode: ImageResizingMode = .aspectFill) {
        self.init([source], resizingMode: resizingMode, contentView: { $0 }, failureView: { DefaultFailureView() })
    }

    init(_ sources: [ImageSource], resizingMode: ImageResizingMode = .aspectFill) {
        self.init(sources, resizingMode: resizingMode, contentView: { $0 }, failureView: { DefaultFailureView() })
    }

    init(sources: [URL], resizingMode: ImageResizingMode = .aspectFill) {
        let imageSources = sources.compactMap { ImageSource(url: $0, blurHash: nil) }
        self.init(imageSources, resizingMode: resizingMode, contentView: { $0 }, failureView: { DefaultFailureView() })
    }
}
