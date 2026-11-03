//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct PreviewImageView: View {

        @Environment(VideoPlayer.ViewState.self)
        private var viewState

        @State
        private var image: UIImage?

        let previewImageProvider: PreviewImageProvider

        var body: some View {
            ZStack {
                Color.black

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .id(image.hashValue)
                }
            }
            .task(id: viewState.scrubbedSeconds, priority: .userInitiated) {
                let newImage = await previewImageProvider.image(for: viewState.scrubbedSeconds)
                guard !Task.isCancelled else { return }

                image = newImage
            }
        }
    }
}
