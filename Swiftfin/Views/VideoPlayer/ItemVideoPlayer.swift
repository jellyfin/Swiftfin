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

class TimerProxy: ObservableObject {
    
    @Published
    var isActive = false
    @Published
    var wasForceStopped = false
    
    private var dismissTimer: Timer?
    
    func start(_ interval: Double) {
        print("Started timer")
        isActive = true
        wasForceStopped = false
        restartOverlayDismissTimer(interval: interval)
    }
    
    func stop() {
        print("Force stopped timer")
        dismissTimer?.invalidate()
        wasForceStopped = true
    }
    
    private func restartOverlayDismissTimer(interval: Double) {
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(dismissTimerFired),
            userInfo: nil,
            repeats: false
        )
    }
    
    @objc
    private func dismissTimerFired() {
        isActive = false
        wasForceStopped = false
    }
}

struct CustomizeView: View {
    
    @EnvironmentObject
    var viewModel: ItemVideoPlayerViewModel
    
    var body: some View {
        VStack {
            HStack  {
                Button {
                    withAnimation {
                        viewModel.presentSettings = false
                    }
                } label: {
                    Image(systemName: "xmark")
                }
                
                Text("Hello there")
                
                Spacer()
            }
            
            Form {
                Button {
                    viewModel.proxy.jumpBackward(10)
                } label: {
                    Text("Here")
                }

            }
        }
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

private struct CurrentOverlayType: EnvironmentKey {
    static let defaultValue: Binding<ItemVideoPlayer.OverlayType?> = .constant(nil)
}

extension EnvironmentValues {
    var currentOverlayType: Binding<ItemVideoPlayer.OverlayType?> {
        get { self[CurrentOverlayType.self] }
        set { self[CurrentOverlayType.self] = newValue }
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
    private var overlayTimer: TimerProxy = .init()
    @State
    private var currentSeconds: Int = 0
    @State
    private var currentOverlayType: OverlayType?

    @ViewBuilder
    func playerView(with viewModel: ItemVideoPlayerViewModel) -> some View {
        HStack(spacing : 0) {
            ZStack(alignment: .bottom) {
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
                    if let currentOverlayType {
                        switch currentOverlayType {
                        case .main:
                            Overlay()
                                .environmentObject(overlayTimer)
                        case .chapters:
                            Overlay.ChapterOverlay()
                        }
                    }
                }
                .environmentObject(viewModel)
                .environmentObject(currentSecondsHandler)
                .environment(\.currentOverlayType, $currentOverlayType)
            }
            .onTapGesture {
                print("Parent got tap gesture")
                overlayTimer.start(5)
            }
            .animation(.linear(duration: 0.1), value: currentOverlayType)
            
//            if viewModel.presentSettings {
//                CustomizeView()
//                    .environmentObject(viewModel)
//                    .frame(maxWidth: reader.size.width * 0.4)
//                    .transition(.asymmetric(
//                        insertion: .opacity,
//                        removal: .move(edge: .trailing)))
//            }
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

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
