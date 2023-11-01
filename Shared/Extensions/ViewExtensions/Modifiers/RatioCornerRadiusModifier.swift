//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct RatioCornerRadiusModifier: ViewModifier {

    @State
    private var cornerRadius: CGFloat = 0

    let corners: UIRectCorner
    let ratio: CGFloat
    let side: KeyPath<CGSize, CGFloat>

    func body(content: Content) -> some View {
        content
            .cornerRadius(cornerRadius, corners: corners)
            .onSizeChanged { newSize in
                cornerRadius = newSize[keyPath: side] * ratio
            }
    }
}
