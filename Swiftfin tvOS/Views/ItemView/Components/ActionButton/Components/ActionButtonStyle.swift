//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ActionButtonStyle: ButtonStyle {

    // MARK: - Focus State

    @Environment(\.isFocused)
    private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            configuration.label
                .modifier(ActionButtonScaleModifier(
                    size: geometry.size,
                    expansion: getExpansionAmount(isPressed: configuration.isPressed),
                    animationDuration: 0.15,
                    isPressed: configuration.isPressed,
                    isFocused: isFocused
                ))
        }
    }

    // MARK: - Expand a Fixed Pixel Amount

    private func getExpansionAmount(isPressed: Bool) -> CGFloat {
        if isPressed {
            return 4
        } else if isFocused {
            return 16
        } else {
            return 0
        }
    }
}
