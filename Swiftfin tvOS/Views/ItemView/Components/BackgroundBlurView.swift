//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct BackgroundBlurView: View {

        var body: some View {
            BlurView(style: .dark)
                .mask {
                    VStack(spacing: 0) {
                        LinearGradient(gradient: Gradient(stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white.opacity(0.7), location: 0.4),
                            .init(color: .white.opacity(0), location: 1),
                        ]), startPoint: .bottom, endPoint: .top)
                            .frame(height: UIScreen.main.bounds.height - 150)

                        Color.white
                    }
                }
        }
    }
}
