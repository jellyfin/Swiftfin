//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import SwiftUI

// MARK: - Container

extension Container {

    var mainServerMessageProxy: Factory<ServerMessageProxy> {
        self { @MainActor in ServerMessageProxy() }.singleton
    }
}

// MARK: - ServerMessageProxy

/// Holds the current server-pushed display message and auto-dismisses
/// after a configurable timeout.
///
/// Unlike `ToastProxy`, this class does not trigger a UIKit presentation —
/// it is a plain `ObservableObject` that views observe directly. This
/// ensures that displaying a server message never interrupts video playback.
@MainActor
final class ServerMessageProxy: ObservableObject {

    @Published
    private(set) var header: String? = nil

    @Published
    private(set) var body: String = ""

    @Published
    var isPresenting: Bool = false

    private let dismissTimer = PokeIntervalTimer()
    private var timerCancellable: AnyCancellable?

    init() {
        timerCancellable = dismissTimer.sink { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.isPresenting = false
            }
        }
    }

    /// Displays a server-pushed message for the given duration.
    func present(header: String?, body: String, timeout: TimeInterval) {
        self.header = header
        self.body = body
        withAnimation(.easeIn(duration: 0.2)) {
            isPresenting = true
        }
        dismissTimer.poke(interval: timeout)
    }
}
