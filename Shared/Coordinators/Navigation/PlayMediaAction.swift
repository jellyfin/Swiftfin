//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import SwiftUI

// TODO: will need additional logic for:
//       - audio playback
//       - remote playback control

@MainActor
struct PlayMediaAction {

    let present: @MainActor (NavigationRoute) -> Void

    func callAsFunction(intent: PlaybackIntent) {
        guard let userSession = Container.shared.currentUserSession() else { return }

        let session = Container.shared.mediaPlayerManager().play(
            intent: intent,
            userSession: userSession
        )

        present(.videoPlayer(session: session))
    }
}

@propertyWrapper
@MainActor
struct PlayMedia: DynamicProperty {

    @Router
    private var router

    var wrappedValue: PlayMediaAction {
        PlayMediaAction { router.route(to: $0) }
    }
}
