//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct OverlayButtonStyle: ButtonStyle {

        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.isFocused)
        private var isFocused

        let onPressed: (Bool) -> Void

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .foregroundStyle(isEnabled ? isFocused ? AnyShapeStyle(Color.black) : AnyShapeStyle(HierarchicalShapeStyle.primary) :
                    AnyShapeStyle(Color.gray)
                )
                .labelStyle(.iconOnly)
                .contentShape(Rectangle())
                .scaleEffect(
                    configuration.isPressed ? 0.8 : 1
                )
                .animation(.bouncy(duration: 0.25, extraBounce: 0.25), value: configuration.isPressed)
                .padding(UIDevice.isTV ? 12 : 4)
                .animation(nil, value: configuration.isPressed)
                .background {
                    Circle()
                        .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.25 : isFocused ? 1 : 0))
                        .scaleEffect(configuration.isPressed ? 1 : 0.9)
                }
                .animation(.linear(duration: 0.1).delay(configuration.isPressed ? 0.2 : 0), value: configuration.isPressed)
                .padding(4)
                .onChange(of: configuration.isPressed, perform: onPressed)
        }
    }
}
