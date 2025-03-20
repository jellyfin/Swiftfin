//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Since ActionButtons are variable in size, a 10% increase is too much for the largest button size but too little for the smallest button
/// This Modifier ensures a fixed PIXEL expansion/contraction is used to ensure a consistent animation
struct ActionButtonScaleModifier: ViewModifier {

    // MARK: - Button Properties

    let size: CGSize

    // MARK: - Expansion Properties

    let expansion: CGFloat
    let animationDuration: Double

    // MARK: - Expansion Reason(s)

    let isPressed: Bool
    let isFocused: Bool

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .scaleEffect(calculateScaleFactor())
            .animation(
                .easeInOut(duration: animationDuration),
                value: isPressed || isFocused
            )
    }

    // MARK: - Calculate Percentage from Properties

    private func calculateScaleFactor() -> CGFloat {
        if expansion == 0 {
            return 1.0
        }
        let baseSize = max(size.width, size.height)

        guard baseSize > 0 else { return 1.0 }

        return (baseSize + (2 * expansion)) / baseSize
    }
}
