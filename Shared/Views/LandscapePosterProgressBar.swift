//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LandscapePosterProgressBar: View {

    let title: String
    let progress: CGFloat

    // Scale padding depending on view width
    @State
    private var paddingScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { reader in
            ZStack(alignment: .bottom) {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.7), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)

                VStack(alignment: .leading, spacing: 3 * paddingScale) {

                    Spacer()

                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.white)

                    ProgressBar(progress: progress)
                }
                .padding(.horizontal, 5 * paddingScale)
                .padding(.bottom, 7 * paddingScale)
                .onAppear {
                    paddingScale = reader.size.width / 300
                }
            }
        }
    }
}
