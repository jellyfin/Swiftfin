//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct MediaSourceInfoView: View {

        @EnvironmentObject
        private var router: MediaSourceInfoCoordinator.Router

        let mediaSource: MediaSourceInfo

        var body: some View {
            Form {
                if let videoStreams = mediaSource.videoStreams,
                   !videoStreams.isEmpty
                {
                    Section("Video") {
                        ForEach(videoStreams, id: \.self) { mediaStream in
                            ChevronButton(title: mediaStream.displayTitle ?? .emptyDash)
                                .onSelect {
                                    router.route(to: \.mediaStreamInfo, mediaStream)
                                }
                        }
                    }
                }

                if let audioStreams = mediaSource.audioStreams,
                   !audioStreams.isEmpty
                {
                    Section("Audio") {
                        ForEach(audioStreams, id: \.self) { mediaStream in
                            ChevronButton(title: mediaStream.displayTitle ?? .emptyDash)
                                .onSelect {
                                    router.route(to: \.mediaStreamInfo, mediaStream)
                                }
                        }
                    }
                }

                if let subtitleStreams = mediaSource.subtitleStreams,
                   !subtitleStreams.isEmpty
                {
                    Section("Subtitle") {
                        ForEach(subtitleStreams, id: \.self) { mediaStream in
                            ChevronButton(title: mediaStream.displayTitle ?? .emptyDash)
                                .onSelect {
                                    router.route(to: \.mediaStreamInfo, mediaStream)
                                }
                        }
                    }
                }
            }
            .navigationTitle(mediaSource.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationCloseButton() {
                router.dismissCoordinator()
            }
        }
    }
}
