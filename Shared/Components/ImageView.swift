//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
import Nuke
import NukeUI
import SwiftUI
import UIKit

private let imagePipeline = ImagePipeline(configuration: .withDataCache)

// TODO: Binding inits?
//       - instead of removing first source on failure, just safe index into sources
struct ImageView: View {

    @State
    private var sources: [ImageSource]

    private var image: (Image) -> any View
    private var placeholder: (() -> any View)?
    private var failure: () -> any View

    @ViewBuilder
    private func _placeholder(_ currentSource: ImageSource) -> some View {
        if let placeholder = placeholder {
            placeholder()
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
                    _image
                        .resizable()
                } else if state.error != nil {
                    failure()
                        .eraseToAnyView()
                        .onAppear {
                            sources.removeFirstSafe()
                        }
                }
            }
            .pipeline(imagePipeline)
        } else {
            failure()
                .eraseToAnyView()
        }
    }
}

extension ImageView {

    init(_ source: ImageSource) {
        self.init(
            sources: [source].compacted(using: \.url),
            image: { $0 },
            placeholder: nil,
            failure: { DefaultFailureView() }
        )
    }

    init(_ sources: [ImageSource]) {
        self.init(
            sources: sources.compacted(using: \.url),
            image: { $0 },
            placeholder: nil,
            failure: { DefaultFailureView() }
        )
    }

    init(_ source: URL?) {
        self.init(
            sources: [ImageSource(url: source)],
            image: { $0 },
            placeholder: nil,
            failure: { DefaultFailureView() }
        )
    }

    init(_ sources: [URL?]) {
        let imageSources = sources
            .compactMap { $0 }
            .map { ImageSource(url: $0) }

        self.init(
            sources: imageSources,
            image: { $0 },
            placeholder: nil,
            failure: { DefaultFailureView() }
        )
    }
}

// MARK: Extensions

extension ImageView {

    func image(@ViewBuilder _ content: @escaping (Image) -> any View) -> Self {
        copy(modifying: \.image, with: content)
    }

    func placeholder(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.placeholder, with: content)
    }

    func failure(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.failure, with: content)
    }
}

// MARK: Defaults

extension ImageView {

    struct DefaultFailureView: View {

        var body: some View {
            Color.secondarySystemFill
        }
    }

    struct DefaultPlaceholderView: View {

        let blurHash: String?

        var body: some View {
            if let blurHash {
                BlurHashView(blurHash: blurHash, size: .Square(length: 8))
            } else {
                Color.secondarySystemFill
            }
        }
    }
}
