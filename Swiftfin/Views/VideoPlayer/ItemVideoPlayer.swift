//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import MediaPlayer
import SwiftUI
import VLCUI

class ItemVideoPlayerManager: ViewModel {

    @Published
    var currentViewModel: ItemVideoPlayerViewModel?

    init(viewModel: ItemVideoPlayerViewModel) {
        self.currentViewModel = viewModel
        super.init()
    }

    init(item: BaseItemDto) {
        super.init()
        item.createItemVideoPlayerViewModel()
            .sink { completion in
                self.handleAPIRequestError(completion: completion)
            } receiveValue: { viewModels in
                self.currentViewModel = viewModels[0]
            }
            .store(in: &cancellables)
    }
}

struct ItemVideoPlayer: View {

    @ObservedObject
    var viewModel: ItemVideoPlayerManager
    @State
    private var showOverlay: Bool = false

    @ViewBuilder
    func playerView(with viewModel: ItemVideoPlayerViewModel) -> some View {
        ZStack(alignment: .bottom) {
            VLCVideoPlayer {
                let configuration = VLCVideoPlayer.Configuration(url: viewModel.playbackURL)
                configuration.autoPlay = true
                configuration.startTime = .seconds(Int32(viewModel.item.startTimeSeconds))
                configuration.playbackChildren = viewModel.subtitleStreams
                    .compactMap(\.asPlaybackChild)
                return configuration
            }
            .eventSubject(viewModel.eventSubject)
            .onTicksUpdated(viewModel.onTicksUpdated(ticks:playbackInformation:))
            .onStateUpdated(viewModel.onStateUpdated(state:playbackInformation:))

            GestureView()
                .onPinch { state, scale in
                    guard state == .began || state == .changed else { return }
                    if scale > 1, !viewModel.isAspectFilled {
                        viewModel.isAspectFilled.toggle()
                        UIView.animate(withDuration: 0.2) {
                            viewModel.eventSubject.send(.aspectFill(1))
                        }
                    } else if scale < 1, viewModel.isAspectFilled {
                        viewModel.isAspectFilled.toggle()
                        UIView.animate(withDuration: 0.2) {
                            viewModel.eventSubject.send(.aspectFill(0))
                        }
                    }
                }
                .onTap {
                    showOverlay.toggle()
                }

            Overlay(viewModel: viewModel)
                .opacity(showOverlay ? 1 : 0)
        }
        .onTapGesture {
            print("Parent got tap gesture")
        }
        .animation(.linear(duration: 0.1), value: showOverlay)
    }

    // TODO: Better and localize
    @ViewBuilder
    private var loadingView: some View {
        VStack {
            ProgressView()

            Text("Retrieving media...")
                .foregroundColor(.white)
        }
    }

    var body: some View {
        Group {
            if let viewModel = viewModel.currentViewModel {
                playerView(with: viewModel)
            } else {
                loadingView
            }
        }
        .supportedOrientations(UIDevice.current.userInterfaceIdiom == .pad ? .all : .landscape)
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .ignoresSafeArea()
    }
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
