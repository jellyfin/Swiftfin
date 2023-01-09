//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LandscapePosterProgressBar: View {

    let title: String
    let progress: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.7),
                    .init(color: .black.opacity(0.7), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 3) {

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)

                ProgressBar(progress: progress)
                    .frame(height: 5)
            }
            .padding(.horizontal, 5)
            .padding(.bottom, 7)
        }
    }
}
