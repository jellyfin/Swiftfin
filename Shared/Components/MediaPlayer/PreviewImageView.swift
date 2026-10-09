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

        private struct RequestID: Equatable {
            let provider: ObjectIdentifier
            let index: Int?
        }

        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        @State
        private var image: (index: Int, image: UIImage)? = nil

        let previewImageProvider: any PreviewImageProvider

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        private var requestID: RequestID {
            RequestID(
                provider: ObjectIdentifier(previewImageProvider),
                index: previewImageProvider.imageIndex(for: scrubbedSeconds)
            )
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
            .task(id: requestID, priority: .userInitiated) {
                guard let index = requestID.index else {
                    image = nil
                    return
                }

                // Keep one request per thumbnail, including while it is loading.
                let newImage = await previewImageProvider.image(for: scrubbedSeconds)
                // Providers may finish shared cached work after this view's task is cancelled.
                guard !Task.isCancelled else { return }

                image = newImage.map { (index: index, image: $0) }
            }
        }
    }
}
