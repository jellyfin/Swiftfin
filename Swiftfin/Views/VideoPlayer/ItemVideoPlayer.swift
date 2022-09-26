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
    
    @State
    private var showOverlay: Bool = false
    
    @ViewBuilder
    private var contentView: some View {
        ZStack(alignment: .bottom) {
            VLCVideoPlayer {
                let configuration = VLCVideoPlayer.Configuration(url: viewModel.playbackURL)
                configuration.autoPlay = true
                configuration.startTime = .seconds(Int32(viewModel.item.startTimeSeconds))
                configuration.playbackChildren = viewModel.subtitleStreams
                    .compactMap { $0.asPlaybackChild }
                return configuration
            }
            .eventSubject(viewModel.eventSubject)
            .onTicksUpdated(viewModel.onTicksUpdated(ticks:playbackInformation:))
            .onStateUpdated(viewModel.onStateUpdated(state:playbackInformation:))
            
            Color.red
                .opacity(0.2)
                .onTapGesture {
                    showOverlay.toggle()
                    print("Gesture view was tapped: \(showOverlay)")
                }
            
            if showOverlay {
                Overlay(viewModel: viewModel)
                    .transition(.opacity.animation(.linear(duration: 0.2)))
            }
            
            Text(showOverlay ? "Should show" : "Don't show")
        }
    }

    var body: some View {
//        PreferenceUIHostingControllerView {
            contentView
                .supportedOrientations(UIDevice.current.userInterfaceIdiom == .pad ? .all : .landscape)
                .prefersHomeIndicatorAutoHidden(true)
                .navigationBarHidden(true)
                .statusBar(hidden: true)
//        }
        .ignoresSafeArea()
    }
}
