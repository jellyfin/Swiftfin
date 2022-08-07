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

struct ImageView<FailureView: View>: View {

    @State
    private var sources: [ImageSource]
    private var currentURL: URL? { sources.first?.url }
    private var currentBlurHash: String? { sources.first?.blurHash }
    private var failureView: () -> FailureView
    private var resizingMode: ImageResizingMode

    init(
        _ source: URL?,
        blurHash: String? = nil,
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        let imageSource = ImageSource(url: source, blurHash: blurHash)
        self.init(imageSource, resizingMode: resizingMode, failureView: failureView)
    }

    init(
        _ source: ImageSource,
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        self.init([source], resizingMode: resizingMode, failureView: failureView)
    }

    init(
        _ sources: [ImageSource],
        resizingMode: ImageResizingMode = .aspectFill,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        _sources = State(initialValue: sources)
        self.resizingMode = resizingMode
        self.failureView = failureView
    }

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
        if let currentURL = currentURL {
            LazyImage(source: currentURL) { state in
                if let image = state.image {
                    image
                        .resizingMode(resizingMode)
                } else if state.error != nil {
                    placeholderView.onAppear {
                        sources.removeFirst()
                    }
                } else {
                    placeholderView
                }
            }
            .pipeline(ImagePipeline(configuration: .withDataCache))
            .id(currentURL)
        } else {
            failureView()
        }
    }
}

extension ImageView where FailureView == DefaultFailureView {
    init(_ source: URL?, blurHash: String? = nil, resizingMode: ImageResizingMode = .aspectFill) {
        let imageSource = ImageSource(url: source, blurHash: blurHash)
        self.init([imageSource], resizingMode: resizingMode, failureView: { DefaultFailureView() })
    }

    init(_ source: ImageSource, resizingMode: ImageResizingMode = .aspectFill) {
        self.init([source], resizingMode: resizingMode, failureView: { DefaultFailureView() })
    }

    init(_ sources: [ImageSource], resizingMode: ImageResizingMode = .aspectFill) {
        self.init(sources, resizingMode: resizingMode, failureView: { DefaultFailureView() })
    }

    init(sources: [URL], resizingMode: ImageResizingMode = .aspectFill) {
        let imageSources = sources.compactMap { ImageSource(url: $0, blurHash: nil) }
        self.init(imageSources, resizingMode: resizingMode, failureView: { DefaultFailureView() })
    }
}

struct RefactoredImageView<ImageType: View, PlaceholderView: View, FailureView: View>: View {

    @State
    private var sources: [ImageSource]
    private var currentSource: ImageSource? { sources.first }
    private var resizingMode: ImageResizingMode = .aspectFill
    
    private var image: (NukeUI.Image) -> ImageType
    private var placeholder: (() -> PlaceholderView)?
    private var blurHashView: ((BlurHashView) -> BlurHashView)?
    private var failure: () -> FailureView
    
    private init(
        _ sources: [ImageSource],
        @ViewBuilder image: @escaping (NukeUI.Image) -> ImageType,
        placeHolder: (() -> PlaceholderView)?,
        blurHashView: ((BlurHashView) -> BlurHashView)?,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        _sources = State(initialValue: sources)
        
        self.image = image
        self.placeholder = placeHolder
        self.blurHashView = blurHashView
        self.failure = failureView
    }
    
    @ViewBuilder
    private func _placeholder(_ currentSource: ImageSource) -> some View {
        if let placeholder = placeholder {
            placeholder()
        } else if let blurHashView = blurHashView, let blurHash = currentSource.blurHash {
            blurHashView(BlurHashView(blurHash: blurHash))
        } else {
            EmptyView()
        }
    }

    var body: some View {
        if let currentSource = currentSource {
            LazyImage(source: currentSource.url) { state in
                if let _image = state.image {
                    // Given image
                    image(_image.resizingMode(resizingMode))
                } else if state.error != nil {
                    // Placeholder
                    _placeholder(currentSource).onAppear {
                        sources.removeFirst()
                    }
                } else {
                    EmptyView()
                }
            }
            .pipeline(ImagePipeline(configuration: .withDataCache))
            .id(currentSource)
        } else {
            failure()
        }
    }
}

// MARK: inits

extension RefactoredImageView {
    init(
        _ source: ImageSource,
        @ViewBuilder image: @escaping (NukeUI.Image) -> ImageType,
        @ViewBuilder placeholder: @escaping () -> PlaceholderView,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        self.init([source],
                  image: image,
                  placeHolder: placeholder,
                  blurHashView: nil,
                  failureView: failureView)
    }

    init(
        _ sources: [ImageSource],
        @ViewBuilder image: @escaping (NukeUI.Image) -> ImageType,
        @ViewBuilder placeholder: @escaping () -> PlaceholderView,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        self.init(sources,
                  image: image,
                  placeHolder: placeholder,
                  blurHashView: nil,
                  failureView: failureView)
    }
}

extension RefactoredImageView where PlaceholderView == EmptyView {
    init(
        _ source: ImageSource,
        @ViewBuilder image: @escaping (NukeUI.Image) -> ImageType,
        @ViewBuilder blurHashView: @escaping (BlurHashView) -> BlurHashView,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        self.init([source],
                  image: image,
                  placeHolder: nil,
                  blurHashView: blurHashView,
                  failureView: failureView)
    }
    
    init(
        _ sources: [ImageSource],
        @ViewBuilder image: @escaping (NukeUI.Image) -> ImageType,
        @ViewBuilder blurHashView: @escaping (BlurHashView) -> BlurHashView,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        self.init(sources,
                  image: image,
                  placeHolder: nil,
                  blurHashView: blurHashView,
                  failureView: failureView)
    }
    
    init(
        _ source: ImageSource,
        @ViewBuilder image: @escaping (NukeUI.Image) -> ImageType,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        self.init([source],
                  image: image,
                  placeHolder: nil,
                  blurHashView: { $0 },
                  failureView: failureView)
    }
    
    init(
        _ sources: [ImageSource],
        @ViewBuilder image: @escaping (NukeUI.Image) -> ImageType,
        @ViewBuilder failureView: @escaping () -> FailureView
    ) {
        self.init(sources,
                  image: image,
                  placeHolder: nil,
                  blurHashView: { $0 },
                  failureView: failureView)
    }
}

extension RefactoredImageView where FailureView == DefaultFailureView {
    init(_ source: ImageSource,
         @ViewBuilder image: @escaping (NukeUI.Image) -> ImageType) {
        self.init([source],
                  image: image,
                  placeHolder: nil,
                  blurHashView: { $0 },
                  failureView: { DefaultFailureView() })
    }

    init(_ sources: [ImageSource],
         @ViewBuilder image: @escaping (NukeUI.Image) -> ImageType) {
        self.init(sources,
                  image: image,
                  placeHolder: nil,
                  blurHashView: { $0 },
                  failureView: { DefaultFailureView() })
    }
}

// MARK: Extensions

extension RefactoredImageView {
    func resizingMode(_ mode: ImageResizingMode) -> RefactoredImageView {
        var copy = self
        copy.resizingMode = mode
        return copy
    }
}
