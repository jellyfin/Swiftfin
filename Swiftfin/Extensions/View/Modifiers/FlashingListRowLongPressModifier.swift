//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FlashingListRowLongPressModifier: ViewModifier {

    @Environment(\.colorScheme)
    private var colorScheme

    @State
    private var isFlashing = false

    let action: () -> Void

    func body(content: Content) -> some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onLongPressGesture {
                    action()

                    isFlashing = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.isFlashing = false
                    }
                }

            content
        }
        .listRowBackground(
            ZStack {

                Color.secondarySystemGroupedBackground

                Color.tertiarySystemGroupedBackground
                    .opacity(isFlashing ? 1 : 0)
            }
            .animation(.linear(duration: isFlashing ? 0.2 : 0.4), value: isFlashing)
        )
    }
}
