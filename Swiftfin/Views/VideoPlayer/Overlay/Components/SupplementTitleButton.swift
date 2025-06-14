//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay {

    struct SupplementTitleButton: View {

        @Environment(\.selectedMediaPlayerSupplement)
        @Binding
        private var selection: AnyMediaPlayerSupplement?

        @State
        private var isPressed: Bool = false

        let supplement: AnyMediaPlayerSupplement

        private var isActive: Bool {
            selection?.id == supplement.id
        }

        var body: some View {
            Text(supplement.supplement.title)
                .fontWeight(.semibold)
                .foregroundStyle(isActive ? .black : .white)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background {
                    ZStack {
                        EmptyHitTestView()

                        if isActive {
                            Rectangle()
                                .foregroundStyle(.white)
                        }
                    }
                }
                .overlay {
                    if !isActive {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.white, lineWidth: 4)
                    }
                }
                .mask {
                    RoundedRectangle(cornerRadius: 7)
                }
                .onTapGesture {
                    if isActive {
                        selection = nil
                    } else {
                        selection = supplement
                    }

                    UIDevice.impact(.light)
                }
                .onLongPressGesture(minimumDuration: 0.1) {} onPressingChanged: { isPressing in
                    isPressed = isPressing
                }
                .scaleEffect(
                    x: isPressed ? 0.9 : 1,
                    y: isPressed ? 0.9 : 1,
                    anchor: .init(x: 0.5, y: 0.5)
                )
                .animation(.bouncy(duration: 0.4), value: isPressed)
                .opacity(isPressed ? 0.6 : 1)
        }
    }
}
