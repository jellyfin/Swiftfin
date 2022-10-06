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

        var body: some View {
            ZStack {
                VStack {
                    TopBarView()
                        .padding(.horizontal, 50)

                    Spacer()
                        .allowsHitTesting(false)

                    BottomBarView()
                        .padding(50)
                }
                
                LargePlaybackButtons()
            }
            .background {
                Color.black
                    .opacity(0.5)
                    .allowsHitTesting(false)
            }
        }
    }
}
