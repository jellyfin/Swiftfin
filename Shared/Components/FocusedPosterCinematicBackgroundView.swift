//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(tvOS)
import Defaults
import SwiftUI

struct FocusedPosterCinematicBackgroundView: View {

    @Default(.Customization.Library.cinematicBackground)
    private var isCinematicBackgroundEnabled

    @FocusedValue(\.focusedPoster)
    private var focusedPoster

    var body: some View {
        if isCinematicBackgroundEnabled {
            FadeContentTransitionView(
                item: focusedPoster,
                debounce: 0.5
            ) { item in
                ImageView(item?.landscapeImageSources(environment: .default) ?? [])
                    .failure {
                        EmptyView()
                    }
                    .aspectRatio(contentMode: .fill)
            }
            .blurred()
            .ignoresSafeArea()
        }
    }
}
#endif
