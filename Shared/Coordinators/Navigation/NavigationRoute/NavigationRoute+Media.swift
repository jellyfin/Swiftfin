//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import JellyfinAPI
import PreferencesView
import SwiftUI
import Transmission

extension NavigationRoute {

    @MainActor
    static var liveTV: NavigationRoute {
        NavigationRoute(
            id: "liveTV",
            withNamespace: { .push(.zoom(sourceID: "item", namespace: $0)) }
        ) {
            ContentGroupView(provider: LiveTVGroupProvider())
        }
    }

    static func mediaSourceInfo(source: MediaSourceInfo) -> NavigationRoute {
        NavigationRoute(
            id: "mediaSourceInfo",
            style: .sheet
        ) {
            MediaSourceInfoView(source: source)
        }
    }

    static func mediaStreamInfo(mediaStream: MediaStream) -> NavigationRoute {
        NavigationRoute(id: "mediaStreamInfo") {
            MediaStreamInfoView(mediaStream: mediaStream)
        }
    }

    @MainActor
    static func videoPlayer(
        provider: MediaPlayerItemProvider,
        queue: (any MediaPlayerQueue)? = nil
    ) -> NavigationRoute {
        let manager = MediaPlayerManager(
            provider: provider,
            queue: queue
        )

        return Self.videoPlayer(manager: manager)
    }

    @MainActor
    static func videoPlayer(manager: MediaPlayerManager) -> NavigationRoute {

        Container.shared.mediaPlayerManager.register {
            manager
        }

        Container.shared.mediaPlayerManagerPublisher()
            .send(manager)

        return NavigationRoute(
            id: "videoPlayer",
            style: .fullscreen
        ) {
            VideoPlayer()
        }
    }

    static var remotePlayback: NavigationRoute {
        NavigationRoute(
            id: "remotePlayback",
            style: .sheet
        ) {
            RemotePlaybackPickerView()
        }
    }
}
