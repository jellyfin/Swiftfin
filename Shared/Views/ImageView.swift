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
            blurHashView(BlurHashView(blurHash: blurHash, size: .Circle(radius: 2), pixels: 56))
        } else {
            EmptyView()
        }
    }

    var body: some View {
        if let currentSource = sources.first {
            LazyImage(url: currentSource.url) { state in
                if let _image = state.image {
                    // Given image
                    image(_image)
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

extension ImageView where ImageType == NukeUI.Image, PlaceholderView == EmptyView, FailureView == DefaultFailureView {
    init(_ source: ImageSource) {
        self.init([source],
                  image: { $0 },
                  placeHolder: nil,
                  blurHashView: { $0 },
                  failureView: { DefaultFailureView() })
    }
    
    init(_ sources: [ImageSource]) {
        self.init(sources,
                  image: { $0 },
                  placeHolder: nil,
                  blurHashView: { $0 },
                  failureView: { DefaultFailureView() })
    }
    
    init(_ source: URL?) {
        self.init([ImageSource(url: source, blurHash: nil)],
                  image: { $0 },
                  placeHolder: nil,
                  blurHashView: { $0 },
                  failureView: { DefaultFailureView() })
    }
    
    init(_ sources: [URL?]) {
        self.init(sources.map { ImageSource(url: $0, blurHash: nil) },
                  image: { $0 },
                  placeHolder: nil,
                  blurHashView: { $0 },
                  failureView: { DefaultFailureView() })
    }
}


// MARK: Extensions

extension ImageView {
    @ViewBuilder
    func image<I: View>(@ViewBuilder _ content: @escaping (NukeUI.Image) -> I) -> ImageView<I, PlaceholderView, FailureView> {
        ImageView<I, PlaceholderView, FailureView>(
            sources,
            image: content,
            placeHolder: placeholder,
            blurHashView: blurHashView,
            failureView: failure
        )
    }
    
    @ViewBuilder
    func placeholder<P: View>(@ViewBuilder _ content: @escaping () -> P) -> ImageView<ImageType, P, FailureView> {
        ImageView<ImageType, P, FailureView>(
            sources,
            image: image,
            placeHolder: content,
            blurHashView: blurHashView,
            failureView: failure
        )
    }
    
    @ViewBuilder
    func failure<F: View>(@ViewBuilder _ content: @escaping () -> F) -> ImageView<ImageType, PlaceholderView, F> {
        ImageView<ImageType, PlaceholderView, F>(
            sources,
            image: image,
            placeHolder: placeholder,
            blurHashView: blurHashView,
            failureView: content
        )
    }
}
