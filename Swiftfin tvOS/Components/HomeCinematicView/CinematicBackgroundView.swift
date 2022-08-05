//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Nuke
import SwiftUI
import UIKit

class DynamicCinematicBackgroundViewModel: ObservableObject {

    @Published
    var currentItem: BaseItemDto?
    @Published
    var currentImageView: UIImageView?

    func select(item: BaseItemDto) {

        guard item.id != currentItem?.id else { return }

        currentItem = item

        let itemImageView = UIImageView()

        let backdropImage: URL

        if item.type == .episode {
            backdropImage = item.seriesImageURL(.backdrop, maxWidth: 1920)
        } else {
            backdropImage = item.imageURL(.backdrop, maxWidth: 1920)
        }

        let options = ImageLoadingOptions(transition: .fadeIn(duration: 0.2))

        Nuke.loadImage(with: backdropImage, options: options, into: itemImageView, completion: { _ in })

        currentImageView = itemImageView
    }
}

struct CinematicBackgroundView: UIViewRepresentable {

    @ObservedObject
    var viewModel: DynamicCinematicBackgroundViewModel

    func updateUIView(_ uiView: UICinematicBackgroundView, context: Context) {
        uiView.update(imageView: viewModel.currentImageView ?? UIImageView())
    }

    func makeUIView(context: Context) -> UICinematicBackgroundView {
        UICinematicBackgroundView(initialImageView: viewModel.currentImageView ?? UIImageView())
    }
}
