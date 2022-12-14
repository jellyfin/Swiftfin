//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import VLCUI

struct VideoPlayer: View {

    @EnvironmentObject
    private var router: ItemVideoPlayerCoordinator.Router

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
    private func playerView(with viewModel: VideoPlayerViewModel) -> some View {
        PreferenceUIHostingControllerView {
            ZStack {
                VLCVideoPlayer(configuration: viewModel.vlcVideoPlayerConfiguration)

//                if presentingConfirmClose {
                ConfirmCloseOverlay()
//                        .transition(.opacity)
//                }
            }
            .onMenuPressed {
                if presentingConfirmClose {
                    router.dismissCoordinator()
                } else {
                    presentingConfirmClose = true

                    let task = DispatchWorkItem {
                        self.presentingConfirmClose = false
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
            if let viewModel = videoPlayerManager.currentViewModel {
                playerView(with: viewModel)
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
