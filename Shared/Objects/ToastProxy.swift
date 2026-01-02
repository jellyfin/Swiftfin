//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

@propertyWrapper
struct Toaster: DynamicProperty {

    @EnvironmentObject
    private var toastProxy: ToastProxy

    var wrappedValue: ToastProxy {
        toastProxy
    }
}

@MainActor
class ToastProxy: ObservableObject {

    @Published
    var isPresenting: Bool = false
    @Published
    private(set) var systemName: String? = nil
    @Published
    private(set) var title: Text = Text("")
//    @Published
//    private(set) var messageID: String = ""

    private let pokeTimer = PokeIntervalTimer(defaultInterval: 2)
    private var pokeCancellable: AnyCancellable?

    init() {
        pokeCancellable = pokeTimer
            .sink {
                withAnimation {
                    self.isPresenting = false
                }
            }
    }

    func present(_ title: String, systemName: String? = nil) {
        present(Text(title), systemName: systemName)
    }

    func present(_ title: Text, systemName: String? = nil) {
        self.title = title
        self.systemName = systemName

        poke(equalsPrevious: title == self.title)
    }

    private func poke(equalsPrevious: Bool) {
//        if equalsPrevious {
//            messageID = UUID().uuidString
//        }

        withAnimation(.spring) {
            isPresenting = true
        }

        pokeTimer.poke()
    }
}
