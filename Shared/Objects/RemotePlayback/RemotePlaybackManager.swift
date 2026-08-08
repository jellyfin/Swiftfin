//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Combine
import Foundation

@MainActor
final class RemotePlaybackManager: ObservableObject {

    @Published
    private(set) var state: RemotePlaybackState?

    weak var manager: MediaPlayerManager?

    private(set) lazy var providers: [any RemotePlaybackProvider] = [
        AirPlayRemotePlaybackProvider(manager: manager),
        JellyfinRemotePlaybackProvider(),
        ChromecastRemotePlaybackProvider(),
    ]

    var availableProviders: [any RemotePlaybackProvider] {
        providers.filter(\.isAvailable)
    }

    var isRemotePlayback: Bool {
        (manager?.remoteProxy as? any RemotePlaybackSession) != nil
    }

    init(manager: MediaPlayerManager? = nil) {
        self.manager = manager
    }

    func refresh() {
        for provider in providers {
            provider.refresh()
        }
    }

    func setAirPlayActive(_ active: Bool) {
        if active {
            guard manager?.remoteProxy == nil else { return }

            let deviceName = AVAudioSession.sharedInstance()
                .currentRoute
                .outputs
                .first { $0.portType == .airPlay }?
                .portName

            manager?.remoteProxy = AirPlayPlaybackSession(deviceName: deviceName)
            state = RemotePlaybackState(type: .airPlay, deviceName: deviceName)
        } else if (manager?.remoteProxy as? any CastContentSession) != nil {
            manager?.remoteProxy?.disconnect()
            manager?.remoteProxy = nil
            state = nil
        }
    }

    func stop() {
        manager?.remoteProxy?.disconnect()
        manager?.remoteProxy = nil
        state = nil
    }

    func select(_ session: any RemotePlaybackSession) async {
        manager?.remoteProxy?.disconnect()
        manager?.proxy?.pause()

        manager?.remoteProxy = session
        state = RemotePlaybackState(type: session.route, deviceName: session.deviceName)

        do {
            try await session.connect(startingAt: manager?.seconds ?? .zero)
        } catch {
            // A cast that never connected has no remote progress to recover,
            // so resume the still-loaded local engine directly.
            manager?.remoteProxy = nil
            state = nil
            manager?.proxy?.play()
        }
    }

    func end() {
        guard let session = manager?.remoteProxy else { return }

        session.disconnect()
        manager?.remoteProxy = nil
        state = nil

        if session is any RemotePlaybackSession {
            Task { await manager?.resumeLocal() }
        }
    }
}
