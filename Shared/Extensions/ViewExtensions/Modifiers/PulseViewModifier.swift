//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PulseViewModifier: ViewModifier {

    @Binding
    private var isPulsing: Bool

    @State
    private var active: Bool = false

    private let range: ClosedRange<Double> = 0.5 ... 1.0
    private let duration: TimeInterval = 1.0

    init(isPulsing: Binding<Bool> = .constant(true)) {
        self._isPulsing = isPulsing
    }

    func body(content: Content) -> some View {
        content
            .mask {
                Color.white
                    .opacity(active ? range.lowerBound : range.upperBound)
                    .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: active)
                    .onChange(of: isPulsing) { _ in
                        useTransaction()
                    }
            }
    }

    private func useTransaction() {
        var transaction = Transaction()
        transaction.disablesAnimations = active

        withTransaction(transaction) {
            withAnimation {
                active.toggle()
            }
        }
    }
}
