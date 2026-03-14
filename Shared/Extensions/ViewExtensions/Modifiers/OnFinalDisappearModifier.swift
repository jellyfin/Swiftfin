//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OnFinalDisappearModifier: ViewModifier {

    @StateObject
    private var observer: Observer

    init(action: @escaping () -> Void) {
        _observer = StateObject(wrappedValue: Observer(action: action))
    }

    func body(content: Content) -> some View {
        content
            .background {
                Color.clear
            }
    }

    private class Observer: ObservableObject {

        private let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        deinit {
            action()
        }
    }
}
