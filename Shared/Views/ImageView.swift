//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
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

struct ImageView: View {

    @State
    private var sources: [ImageSource]

    private var image: (NukeUI.Image) -> any View
    private var placeholder: (() -> any View)?
    private var failure: () -> any View
    private var resizingMode: ImageResizingMode

    @ViewBuilder
    private func _placeholder(_ currentSource: ImageSource) -> some View {
        if let placeholder = placeholder {
            placeholder()
                .eraseToAnyView()
        } else if let blurHash = currentSource.blurHash {
            BlurHashView(blurHash: blurHash, size: .Square(length: 16))
        } else {
            DefaultPlaceholderView()
        }
    }

    var body: some View {
        if let currentSource = sources.first {
            LazyImage(url: currentSource.url) { state in
                if state.isLoading {
                    _placeholder(currentSource)
                } else if let _image = state.image {
                    image(_image.resizingMode(resizingMode))
                        .eraseToAnyView()
                } else if state.error != nil {
                    failure()
                        .eraseToAnyView()
                        .onAppear {
                            sources.removeFirstSafe()
                        }
                }
            }
            .pipeline(ImagePipeline(configuration: .withDataCache))
            .id(currentSource)
        } else {
            failure()
                .eraseToAnyView()
        }
    }
}

extension ImageView {
    init(_ source: ImageSource) {
        self.init(
            sources: [source],
            image: { $0 },
            placeholder: nil,
            failure: { DefaultFailureView() },
            resizingMode: .aspectFill
        )
    }

    init(_ sources: [ImageSource]) {
        self.init(
            sources: sources,
            image: { $0 },
            placeholder: nil,
            failure: { DefaultFailureView() },
            resizingMode: .aspectFill
        )
    }

    init(_ source: URL?) {
        self.init(
            sources: [ImageSource(url: source, blurHash: nil)],
            image: { $0 },
            placeholder: nil,
            failure: { DefaultFailureView() },
            resizingMode: .aspectFill
        )
    }

    init(_ sources: [URL?]) {
        self.init(
            sources: sources.map { ImageSource(url: $0, blurHash: nil) },
            image: { $0 },
            placeholder: nil,
            failure: { DefaultFailureView() },
            resizingMode: .aspectFill
        )
    }
}

// MARK: Extensions

extension ImageView {

    func image(@ViewBuilder _ content: @escaping (NukeUI.Image) -> any View) -> Self {
        copy(modifying: \.image, with: content)
    }

    func placeholder(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.placeholder, with: content)
    }

    func failure(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.failure, with: content)
    }

    func resizingMode(_ resizingMode: ImageResizingMode) -> Self {
        copy(modifying: \.resizingMode, with: resizingMode)
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

        var body: some View {
            Color.secondarySystemFill
                .opacity(0.5)
        }
    }
}
