//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

@MainActor
final class AirPlayPlaybackSession: ObservableObject, CastContentSession {

    let route: RemotePlaybackRoute = .airPlay
    let deviceName: String?

    let isBuffering: PublishedBox<Bool> = .init(initialValue: false)

    weak var manager: MediaPlayerManager?

    init(deviceName: String?) {
        self.deviceName = deviceName
    }

    func connect(startingAt seconds: Duration) async throws {}

    func disconnect() {}

    func play() {
        manager?.proxy?.play()
    }

    func pause() {
        manager?.proxy?.pause()
    }

    func stop() {
        manager?.proxy?.stop()
    }

    func jumpForward(_ seconds: Duration) {
        manager?.proxy?.jumpForward(seconds)
    }

    func jumpBackward(_ seconds: Duration) {
        manager?.proxy?.jumpBackward(seconds)
    }

    func setRate(_ rate: Float) {
        manager?.proxy?.setRate(rate)
    }

    func setSeconds(_ seconds: Duration, completion: ((Bool) -> Void)?) {
        manager?.proxy?.setSeconds(seconds, completion: completion)
    }
}
