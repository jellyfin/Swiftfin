//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct BottomEdgeGradientModifier: ViewModifier {

    let bottomColor: Color

    func body(content: Content) -> some View {
        content
            .overlay(
                alignment: .bottom,
                extendedBy: .init(top: 0, leading: 0, bottom: 10, trailing: 0)
            ) {
                EasedGradient(
                    colors: [.clear, bottomColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 50)
            }
            .background(extendedBy: .init(top: 0, leading: 0, bottom: 1000, trailing: 0)) {
                bottomColor
            }
    }
}
