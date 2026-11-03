//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import MPVUI
import Observation

@MainActor
@Observable
final class TextSubtitlePresentation {

    private(set) var snapshot: TextSubtitleSnapshot?

    @ObservationIgnored
    private var observationTask: AnyCancellable?

    func start(_ player: MPVPlayer, onChange: @escaping @MainActor () -> Void = {}) {
        clear()
        player.setTextSubtitleInterceptionEnabled(true)

        let subtitles = player.textSubtitleStream()

        observationTask = Task { [weak self] in
            for await snapshot in subtitles {
                guard !Task.isCancelled else { return }

                self?.snapshot = snapshot
                onChange()
            }
        }
        .asAnyCancellable()
    }

    func clear() {
        observationTask?.cancel()
        observationTask = nil
        snapshot = nil
    }
}
