//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Foundation

@MainActor
final class AirPlayRouteObserver: MediaPlayerObserver {

    weak var manager: MediaPlayerManager?

    private var routeChangeToken: NSObjectProtocol?
    private var wasAirPlayActive = false

    init() {
        routeChangeToken = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.evaluate()
            }
        }
    }

    deinit {
        if let routeChangeToken {
            NotificationCenter.default.removeObserver(routeChangeToken)
        }
    }

    private func evaluate() {
        let isAirPlayActive = AVAudioSession.sharedInstance()
            .currentRoute
            .outputs
            .contains {
                $0.portType == .airPlay
            }

        defer { wasAirPlayActive = isAirPlayActive }

        // Only act on the rising edge — AirPlay routes flap, and re-firing on
        // every route change rebuilds the transcode repeatedly.
        guard isAirPlayActive, !wasAirPlayActive else { return }

        guard let manager,
              let airplayable = manager.proxy as? any AirPlayable,
              !airplayable.supportsAirPlay,
              let target = airplayable.airPlayPlayerType,
              manager.remote.activeSession == nil
        else { return }

        Task {
            await manager.switchPlayer(to: target)
        }
    }
}
