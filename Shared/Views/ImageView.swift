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

// TODO: Fix 100+ inits

struct ImageViewSource {
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

struct ImageView<FailureView: View>: View {

    @State
    private var sources: [ImageViewSource]
    private var currentURL: URL? { sources.first?.url }
    private var currentBlurHash: String? { sources.first?.blurHash }
    private var failureView: FailureView

    init(_ source: URL?, blurHash: String? = nil, @ViewBuilder failureView: () -> FailureView) {
        let imageViewSource = ImageViewSource(url: source, blurHash: blurHash)
        _sources = State(initialValue: [imageViewSource])
        self.failureView = failureView()
    }

    init(_ source: ImageViewSource, @ViewBuilder failureView: () -> FailureView) {
        _sources = State(initialValue: [source])
        self.failureView = failureView()
    }

    init(_ sources: [ImageViewSource], @ViewBuilder failureView: () -> FailureView) {
        _sources = State(initialValue: sources)
        self.failureView = failureView()
    }

    @ViewBuilder
    private var placeholderView: some View {
        if let currentBlurHash = currentBlurHash {
            BlurHashView(blurHash: currentBlurHash)
                .id(currentBlurHash)
        } else {
            Color.secondary
        }
    }

    var body: some View {

        if let currentURL = currentURL {
            LazyImage(source: currentURL) { state in
                if let image = state.image {
                    image
                } else if state.error != nil {
                    placeholderView.onAppear { sources.removeFirst() }
                } else {
                    placeholderView
                }
            }
            .pipeline(ImagePipeline(configuration: .withDataCache))
            .id(currentURL)
        } else {
            failureView
        }
    }
}

extension ImageView where FailureView == DefaultFailureView {
    init(_ source: URL?, blurHash: String? = nil) {
        let imageViewSource = ImageViewSource(url: source, blurHash: blurHash)
        self.init(imageViewSource, failureView: { DefaultFailureView() })
    }

    init(_ source: ImageViewSource) {
        self.init(source, failureView: { DefaultFailureView() })
    }

    init(_ sources: [ImageViewSource]) {
        self.init(sources, failureView: { DefaultFailureView() })
    }

    init(sources: [URL]) {
        let imageViewSources = sources.compactMap { ImageViewSource(url: $0, blurHash: nil) }
        self.init(imageViewSources, failureView: { DefaultFailureView() })
    }
}
