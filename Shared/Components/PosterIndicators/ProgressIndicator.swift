//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ProgressIndicator: View {

    @Default(.accentColor)
    private var accentColor

    let progress: CGFloat
    let height: CGFloat

    // Very thin outline on the top and trailing edges of the filled bar so it
    // stays visible against light/white poster artwork. Sized by width (rather
    // than scaleEffect) so the right border keeps a constant thickness.
    private let borderWidth: CGFloat = 1
    private let borderColor = Color.black.opacity(0.4)

    var body: some View {
        GeometryReader { proxy in
            accentColor
                .frame(width: proxy.size.width * progress, height: height)
                .overlay(alignment: .top) {
                    borderColor
                        .frame(height: borderWidth)
                }
                .overlay(alignment: .trailing) {
                    borderColor
                        .frame(width: borderWidth)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}
