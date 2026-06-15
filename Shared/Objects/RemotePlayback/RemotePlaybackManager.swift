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
    private(set) var activeSession: (any RemotePlaybackSession)?

    @Published
    private(set) var state: RemotePlaybackState?

    weak var manager: MediaPlayerManager?

    private weak var localProxy: (any MediaPlayerProxy)?

    init(manager: MediaPlayerManager? = nil) {
        self.manager = manager
    }

    func setAirPlayActive(_ active: Bool) {
        guard activeSession == nil else { return }

        if active {
            let deviceName = AVAudioSession.sharedInstance()
                .currentRoute
                .outputs
                .first { $0.portType == .airPlay }?
                .portName

            state = RemotePlaybackState(type: .airPlay, deviceName: deviceName)
        } else if state?.type == .airPlay {
            state = nil
        }
    }

    // The local proxy can be created after a session is already active (remote
    // started before the video loaded). Adopt it so the return resumes on it.
    func registerLocal(_ proxy: any MediaPlayerProxy) {
        guard activeSession != nil, localProxy == nil else { return }
        localProxy = proxy
    }

    func stop() {
        activeSession?.disconnect()
        activeSession = nil
        state = nil
        localProxy = nil
    }

    func select(_ session: any RemotePlaybackSession) async {
        if activeSession == nil {
            localProxy = manager?.proxy
        }

        localProxy?.pause()

        var session = session
        session.manager = manager

        activeSession = session
        manager?.proxy = session
        state = RemotePlaybackState(type: session.route, deviceName: session.deviceName)

        do {
            try await session.connect(startingAt: manager?.seconds ?? .zero)
        } catch {
            restoreLocalInPlace()
        }
    }

    // A cast that never connected has no remote progress to recover, so resume
    // the still-loaded local proxy directly instead of rebuilding the item.
    private func restoreLocalInPlace() {
        activeSession = nil
        state = nil

        guard let local = localProxy else { return }
        localProxy = nil
        manager?.proxy = local
        local.play()
    }

    func end() {
        activeSession?.disconnect()
        activeSession = nil
        state = nil

        if let local = localProxy {
            localProxy = nil
            Task { await manager?.resumeLocal(on: local) }
        }
    }

    func end(route: RemotePlaybackRoute) {
        guard state?.type == route else { return }
        end()
    }
}
