//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct MediaSourceInfoView: View {

    @EnvironmentObject
    private var router: MediaSourceInfoCoordinator.Router

    let source: MediaSourceInfo

    var body: some View {
        Form {
            if let videoStreams = source.videoStreams,
               videoStreams.isNotEmpty
            {
                Section(L10n.video) {
                    ForEach(videoStreams, id: \.self) { stream in
                        ChevronButton(stream.displayTitle ?? .emptyDash)
                            .onSelect {
                                router.route(to: \.mediaStreamInfo, stream)
                            }
                    }
                }
            }

            if let audioStreams = source.audioStreams,
               audioStreams.isNotEmpty
            {
                Section(L10n.audio) {
                    ForEach(audioStreams, id: \.self) { stream in
                        ChevronButton(stream.displayTitle ?? .emptyDash)
                            .onSelect {
                                router.route(to: \.mediaStreamInfo, stream)
                            }
                    }
                }
            }

            if let subtitleStreams = source.subtitleStreams,
               subtitleStreams.isNotEmpty
            {
                Section(L10n.subtitle) {
                    ForEach(subtitleStreams, id: \.self) { stream in
                        ChevronButton(stream.displayTitle ?? .emptyDash)
                            .onSelect {
                                router.route(to: \.mediaStreamInfo, stream)
                            }
                    }
                }
            }
        }
        .navigationTitle(source.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
    }
}
