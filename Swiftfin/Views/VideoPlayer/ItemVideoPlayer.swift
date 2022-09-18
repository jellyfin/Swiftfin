//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI
import VLCUI

struct ItemVideoPlayer: View {
    
    @ObservedObject
    var viewModel: ItemVideoPlayerViewModel
    
    var body: some View {
        PreferenceUIHostingControllerView {
            ZStack {
                VLCVideoPlayer(url: viewModel.playbackURL)
                    .delegate(viewModel)
                    .configure { configuration in
                        configuration.autoPlay = true
                    }
                
                Button {
                    viewModel.jump(to: 2146000)
                } label: {
                    Text("Resume")
                        .padding()
                        .background(Color.blue.opacity(0.5))
                        .cornerRadius(10)
                }
            }
            .supportedOrientations(UIDevice.current.userInterfaceIdiom == .pad ? .all : .landscape)
            .navigationBarHidden(true)
            .statusBar(hidden: true)
        }
        .ignoresSafeArea()
    }
}
