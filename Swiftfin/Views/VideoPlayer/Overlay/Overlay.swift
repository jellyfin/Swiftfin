//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Sliders
import SwiftUI
import VLCUI

extension ItemVideoPlayer {

    struct Overlay: View {
        
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets
        
        init() { }

        var body: some View {
            ZStack {
                VStack {
                    TopBarView()
                        .padding(safeAreaInsets)
                        .opacity(isScrubbing ? 0 : 1)

                    Spacer()
                        .allowsHitTesting(false)

                    BottomBarView()
                        .padding(safeAreaInsets)
                }
                
                LargePlaybackButtons()
                    .opacity(isScrubbing ? 0 : 1)
            }
            .background {
                Color.black
                    .opacity(isScrubbing ? 0 : 0.5)
                    .allowsHitTesting(false)
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
        }
    }
}
