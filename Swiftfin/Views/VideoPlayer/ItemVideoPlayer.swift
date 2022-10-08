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

extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap {
                $0 as? UIWindowScene
            }
            .flatMap(\.windows)
            .first {
                $0.isKeyWindow
            }
    }
}

struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets.swiftUiInsets ?? .zero
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

extension UIEdgeInsets {

    var swiftUiInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

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

    enum OverlayType {
        case main
        case chapters
    }

    @ObservedObject
    var viewModel: ItemVideoPlayerManager
    @ObservedObject
    private var currentSecondsHandler: CurrentSecondsHandler = .init()
    @ObservedObject
    private var flashContentProxy: FlashContentProxy = .init()
    @ObservedObject
    private var overlayTimer: TimerProxy = .init()
    @State
    private var isScrubbing: Bool = false
    @State
    private var currentOverlayType: OverlayType?

    @ViewBuilder
    func playerView(with viewModel: ItemVideoPlayerViewModel) -> some View {
        HStack(spacing: 0) {
            ZStack {
                VLCVideoPlayer(configuration: viewModel.configuration)
                    .proxy(viewModel.proxy)
                    .onTicksUpdated {
                        viewModel.onTicksUpdated(ticks: $0, playbackInformation: $1)
                        currentSecondsHandler.onTicksUpdated(ticks: $0, playbackInformation: $1)
                    }
                    .onStateUpdated(viewModel.onStateUpdated(state:playbackInformation:))

                GestureView()
                    .onPinch { state, scale in
                        guard state == .began || state == .changed else { return }
                        if scale > 1, !viewModel.isAspectFilled {
                            viewModel.isAspectFilled.toggle()
                            UIView.animate(withDuration: 0.2) {
                                viewModel.proxy.aspectFill(1)
                            }
                        } else if scale < 1, viewModel.isAspectFilled {
                            viewModel.isAspectFilled.toggle()
                            UIView.animate(withDuration: 0.2) {
                                viewModel.proxy.aspectFill(0)
                            }
                        }
                    }
                    .onTap {
                        if currentOverlayType == nil {
                            currentOverlayType = .main
                        } else {
                            currentOverlayType = nil
                        }
                    }

                Group {
                    switch currentOverlayType {
                    case .main:
                        Overlay()
                    case .chapters:
                        Overlay.ChapterOverlay()
                    case .none:
                        EmptyView()
                    }
                }
                .transition(.opacity)
                .environmentObject(currentSecondsHandler)
                .environmentObject(flashContentProxy)
                .environmentObject(overlayTimer)
                .environmentObject(viewModel)
                .environment(\.currentOverlayType, $currentOverlayType)
                .environment(\.isScrubbing, $isScrubbing)

                FlashContentView(proxy: flashContentProxy)
            }
            .onTapGesture {
                print("Parent got tap gesture")
                overlayTimer.start(5)
            }
            .animation(.linear(duration: 0.1), value: currentOverlayType)

            // TODO: Add advanced menu
        }
        .onChange(of: overlayTimer.isActive) { newValue in
            guard !newValue else { return }
            currentOverlayType = nil
        }
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
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .ignoresSafeArea()
    }
}
