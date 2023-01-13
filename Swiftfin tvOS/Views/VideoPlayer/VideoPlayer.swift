//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import VLCUI

struct VideoPlayer: View {

    @EnvironmentObject
    private var router: VideoPlayerCoordinator.Router

    @ObservedObject
    private var videoPlayerManager: VideoPlayerManager

    @State
    private var presentingConfirmClose: Bool = false
    @State
    private var confirmCloseWorkItem: DispatchWorkItem?

    init(manager: VideoPlayerManager) {
        self.videoPlayerManager = manager
    }

    @ViewBuilder
    private var playerView: some View {
        PreferenceUIHostingControllerView {
            ZStack {
//                VLCVideoPlayer(configuration: videoPlayerManager.currentViewModel.vlcVideoPlayerConfiguration)

                Color.red
                    .opacity(0.5)
                    .visible(presentingConfirmClose)
                
                
//                ConfirmCloseOverlay()
//                    .visible(presentingConfirmClose)
            }
            .onMenuPressed {
                confirmCloseWorkItem?.cancel()
                
                if presentingConfirmClose {
                    router.dismissCoordinator()
                } else {
                    withAnimation {
                        presentingConfirmClose = true
                    }

                    let task = DispatchWorkItem {
                        withAnimation {
                            self.presentingConfirmClose = false
                        }
                    }

                    confirmCloseWorkItem = task

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: task)
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var loadingView: some View {
        Text("Retrieving media information")
    }

    var body: some View {
        Group {
            if let _ = videoPlayerManager.currentViewModel {
                playerView
            } else {
                loadingView
            }
        }
    }
}

extension VideoPlayer {

    enum OverlayType {
        case main
        case chapters
    }
}
