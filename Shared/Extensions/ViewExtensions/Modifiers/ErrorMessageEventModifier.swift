//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

// TODO: determine if Router check is best way

struct ErrorMessageEventModifier<Events: Publisher>: ViewModifier where Events.Output: WithErrorEvent, Events.Failure == Never {

    @Environment(\.router)
    private var router

    @State
    private var error: Error? = nil

    let dismissAction: () -> Void
    let events: Events

    @ContentBuilder
    func body(content: Content) -> some View {
        content
            .onReceive(events) { event in
                guard router.navigationCoordinator?.presentedSheet == nil,
                      router.navigationCoordinator?.presentedFullScreen == nil,
                      let error = event.error else { return }

                self.error = error
            }
            .errorMessage($error, dismissAction: dismissAction)
    }
}
