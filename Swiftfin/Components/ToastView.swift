//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

class ToastProxy: ObservableObject {

    @Published
    private(set) var isPresenting: Bool = false
    @Published
    private(set) var systemName: String? = nil
    @Published
    private(set) var title: Text = Text("")
    @Published
    private(set) var messageID: String = ""

    private let pokeTimer = PokeIntervalTimer(defaultInterval: 1)
    private var pokeCancellable: AnyCancellable?

    init() {
        pokeCancellable = pokeTimer.hasFired
            .sink {
                self.isPresenting = false
            }
    }

    func present(_ title: String, systemName: String? = nil) {
        self.title = Text(title)
        self.systemName = systemName

        poke()
    }

    func present(_ title: Text, systemName: String? = nil) {
        self.title = title
        self.systemName = systemName

        poke()
    }

    private func poke() {
        isPresenting = true
        messageID = UUID().uuidString
        pokeTimer.poke()
    }
}

struct ToastView: View {

    @EnvironmentObject
    private var proxy: ToastProxy

    var body: some View {
        ZStack {
            if proxy.isPresenting {
                HStack {
                    if let systemName = proxy.systemName {
                        Image(systemName: systemName)
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                    }

                    proxy.title
                        .font(.body)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .frame(minHeight: 50)
                .background(BlurView())
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 6)
                .transition(.opacity)
                .animation(.linear(duration: 0.2), value: proxy.messageID)
            }
        }
        .animation(.spring, value: proxy.isPresenting)
    }
}
