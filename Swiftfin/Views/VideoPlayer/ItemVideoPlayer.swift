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
                    .compactMap { $0.asPlaybackChild }
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
                .onVerticalPan { _, translation in
                    MPVolumeView.setVolume(Float(abs(translation.y)) / 500)
                }
            
            Overlay(viewModel: viewModel)
                .opacity(showOverlay ? 1 : 0)
            
            Text(showOverlay ? "Should show" : "Don't show")
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

struct GestureView: UIViewRepresentable {
    
    private var onPinch: (UIGestureRecognizer.State, CGFloat) -> Void
    private var onTap: () -> Void
    private var onVerticalPan: (CGPoint, CGPoint) -> Void
    private var onHorizontalPan: (CGPoint, CGPoint) -> Void
    
    func makeUIView(context: Context) -> UIGestureView {
        UIGestureView(
            onPinch: onPinch,
            onTap: onTap,
            onVerticalPan: onVerticalPan,
            onHorizontalPan: onHorizontalPan
        )
    }
    
    func updateUIView(_ uiView: UIGestureView, context: Context) {
        
    }
}

extension GestureView {
    
    init() {
        self.onPinch = { _, _ in }
        self.onTap = { }
        self.onVerticalPan = { _, _ in }
        self.onHorizontalPan = { _, _ in }
    }
    
    func onPinch(_ action: @escaping (UIGestureRecognizer.State, CGFloat) -> Void) -> Self {
        copy(modifying: \.onPinch, with: action)
    }
    
    func onTap(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onTap, with: action)
    }
    
    func onVerticalPan(_ action: @escaping (CGPoint, CGPoint) -> Void) -> Self {
        copy(modifying: \.onVerticalPan, with: action)
    }
    
    func onHorizontalPan(_ action: @escaping (CGPoint, CGPoint) -> Void) -> Self {
        copy(modifying: \.onVerticalPan, with: action)
    }
}

class UIGestureView: UIView {
    
    private let onPinch: (UIGestureRecognizer.State, CGFloat) -> Void
    private let onTap: () -> Void
    private let onVerticalPan: (CGPoint, CGPoint) -> Void
    private let onHorizontalPan: (CGPoint, CGPoint) -> Void
    
    init(
        onPinch: @escaping (UIGestureRecognizer.State, CGFloat) -> Void,
        onTap: @escaping () -> Void,
        onVerticalPan: @escaping (CGPoint, CGPoint) -> Void,
        onHorizontalPan: @escaping (CGPoint, CGPoint) -> Void
    ) {
        self.onPinch = onPinch
        self.onTap = onTap
        self.onVerticalPan = onVerticalPan
        self.onHorizontalPan = onHorizontalPan
        super.init(frame: .zero)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPerformPinch(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didPerformTap(_:)))
        let verticalPanGesture = PanDirectionGestureRecognizer(direction: .vertical, target: self, action: #selector(didPerformVerticalPan(_:)))
        let horizontalPanGesture = PanDirectionGestureRecognizer(direction: .horizontal, target: self, action: #selector(didPerformHorizontalPan(_:)))
        
        addGestureRecognizer(pinchGesture)
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(verticalPanGesture)
        addGestureRecognizer(horizontalPanGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func didPerformPinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        onPinch(gestureRecognizer.state, gestureRecognizer.scale)
    }
    
    @objc
    private func didPerformTap(_ gestureRecognizer: UITapGestureRecognizer) {
        onTap()
    }
    
    @objc
    private func didPerformVerticalPan(_ gestureRecognizer: PanDirectionGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        let translation = gestureRecognizer.translation(in: self)
        onVerticalPan(location, translation)
    }
    
    @objc
    private func didPerformHorizontalPan(_ gestureRecognizer: PanDirectionGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        let translation = gestureRecognizer.translation(in: self)
        onHorizontalPan(location, translation)
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
