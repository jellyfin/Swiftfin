//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct PreviewImageView: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        @State
        private var image: (index: Int, image: UIImage)? = nil
        @State
        private var currentImageTask: AnyCancellable? = nil

        let previewImageProvider: any PreviewImageProvider

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        var body: some View {
            ZStack {
                Color.black

                ZStack {
                    if let image {
                        Image(uiImage: image.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .id(image?.index)
            }
            .onChange(of: scrubbedSeconds) { newValue in
                let newIndex = previewImageProvider.imageIndex(for: newValue)

                if newIndex != image?.index {
                    currentImageTask?.cancel()
                    currentImageTask = nil

                    let newTask = Task(priority: .userInitiated) {
                        if let image = await previewImageProvider.image(for: newValue) {
                            self.image = (index: newIndex, image: image)
                        } else {
                            self.image = nil
                        }
                    }

                    currentImageTask = newTask.asAnyCancellable()
                }
            }
        }
    }
}
