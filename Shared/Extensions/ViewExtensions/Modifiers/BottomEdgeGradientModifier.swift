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
        VStack(spacing: 0) {
            content
                .mask {
                    VStack(spacing: 0) {
                        Color.black

                        LinearGradient(
                            colors: [.black, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 10)
                    }
                }
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(bottomColor)
    }
}
