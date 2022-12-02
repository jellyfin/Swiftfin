//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import MediaPlayer
import Stinsen
import SwiftUI
import VLCUI

// TODO: organize

class CurrentProgressHandler: ObservableObject {
    
    @Published
    var progress: CGFloat = 0
    @Published
    var scrubbedProgress: CGFloat = 0
    
    @Published
    var seconds: Int = 0
    @Published
    var scrubbedSeconds: Int = 0
}

struct ItemVideoPlayer: View {
    
    enum OverlayType {
        case main
        case chapters
    }
    
    class GestureStateHandler {
        
        var beganPanWithOverlay: Bool = false
        var beginningPanProgress: CGFloat = 0
        var beginningHorizontalPanUnit: CGFloat = 0
        
        var beginningAudioOffset: Int = 0
        var beginningBrightnessValue: CGFloat = 0
        var beginningPlaybackSpeed: Float = 0
        var beginningSubtitleOffset: Int = 0
        var beginningVolumeValue: Float = 0
    }
    
    @Default(.VideoPlayer.jumpBackwardLength)
    private var jumpBackwardLength
    @Default(.VideoPlayer.jumpForwardLength)
    private var jumpForwardLength
    
    @Default(.VideoPlayer.Gesture.horizontalPanGesture)
    private var horizontalPanGesture
    @Default(.VideoPlayer.Gesture.horizontalSwipeGesture)
    private var horizontalSwipeGesture
    @Default(.VideoPlayer.Gesture.longPressGesture)
    private var longPressGesture
    @Default(.VideoPlayer.Gesture.multiTapGesture)
    private var multiTapGesture
    @Default(.VideoPlayer.Gesture.pinchGesture)
    private var pinchGesture
    @Default(.VideoPlayer.Gesture.verticalPanGestureLeft)
    private var verticalGestureLeft
    @Default(.VideoPlayer.Gesture.verticalPanGestureRight)
    private var verticalGestureRight

    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize

    @EnvironmentObject
    private var router: ItemVideoPlayerCoordinator.Router
    
    @ObservedObject
    private var currentProgressHandler: CurrentProgressHandler = .init()
    @ObservedObject
    private var overlayTimer: TimerProxy = .init()
    @ObservedObject
    private var splitContentViewProxy: SplitContentViewProxy = .init()
    @ObservedObject
    private var videoPlayerManager: VideoPlayerManager
    
    @ObservedObject
    private var updateViewProxy: UpdateViewProxy = .init()

    @State
    private var aspectFilled: Bool = false
    @State
    private var audioOffset: Int = 0
    @State
    private var currentOverlayType: OverlayType?
    @State
    private var gestureLocked: Bool = false
    @State
    private var isScrubbing: Bool = false
    @State
    private var subtitleOffset: Int = 0
    
    private let gestureStateHandler: GestureStateHandler = .init()

    init(manager: VideoPlayerManager) {
        self.videoPlayerManager = manager
    }

    @ViewBuilder
    private func playerView(with viewModel: VideoPlayerViewModel) -> some View {
        SplitContentView()
            .proxy(splitContentViewProxy)
            .content {
                ZStack {
                    VLCVideoPlayer(configuration: viewModel.vlcVideoPlayerConfiguration)
                        .proxy(videoPlayerManager.proxy)
                        .onTicksUpdated { ticks, playbackInformation in
                            videoPlayerManager.onTicksUpdated(ticks: ticks, playbackInformation: playbackInformation)
                            
                            let newSeconds = ticks / 1000
                            let newProgress = CGFloat(newSeconds) / CGFloat(viewModel.item.runTimeSeconds)
                            currentProgressHandler.progress = newProgress
                            currentProgressHandler.seconds = newSeconds

                            guard !isScrubbing else { return }
                            currentProgressHandler.scrubbedProgress = newProgress
                        }
                        .onStateUpdated(videoPlayerManager.onStateUpdated(state:playbackInformation:))

                    GestureView()
                        .onHorizontalPan {
                            handlePan(action: horizontalPanGesture, state: $0, point: $1.x, velocity: $2, translation: $3)
                        }
                        .onHorizontalSwipe(translation: 100, velocity: 1500, sameSwipeDirectionTimeout: 1, handleHorizontalSwipe)
                        .onLongPress(minimumDuration: 2, handleLongPress)
                        .onPinch(handlePinchGesture)
                        .onTap(samePointPadding: 10, samePointTimeout: 0.7, handleTapGesture)
                        .onVerticalPan {
                            if $1.x <= 0.5 {
                                handlePan(action: verticalGestureLeft, state: $0, point: -$1.y, velocity: $2, translation: $3)
                            } else {
                                handlePan(action: verticalGestureRight, state: $0, point: -$1.y, velocity: $2, translation: $3)
                            }
                        }
                    
                    Group {
                        Overlay()
//                            .opacity(currentOverlayType == .main ? 1 : 0)
                        
//                        Overlay.ChapterOverlay()
//                            .opacity(currentOverlayType == .chapters ? 1 : 0)
                    }
                    .environmentObject(currentProgressHandler)
                    .environmentObject(overlayTimer)
                    .environmentObject(splitContentViewProxy)
                    .environmentObject(videoPlayerManager)
                    .environmentObject(videoPlayerManager.proxy)
                    .environmentObject(videoPlayerManager.currentViewModel!)
                    .environment(\.aspectFilled, $aspectFilled)
                    .environment(\.currentOverlayType, $currentOverlayType)
                    .environment(\.isScrubbing, $isScrubbing)
                }
                .onTapGesture {
                    overlayTimer.start(5)
                }
            }
            .splitContent {
                WrappedView {
                    NavigationViewCoordinator(PlaybackSettingsCoordinator()).view()
                }
                    .cornerRadius(20, corners: [.topLeft, .bottomLeft])
                    .environmentObject(splitContentViewProxy)
                    .environmentObject(viewModel)
                    .environmentObject(videoPlayerManager)
                    .environment(\.audioOffset, $audioOffset)
                    .environment(\.subtitleOffset, $subtitleOffset)
            }
            .onChange(of: currentProgressHandler.scrubbedProgress) { newValue in
                currentProgressHandler.scrubbedSeconds = Int(CGFloat(viewModel.item.runTimeSeconds) * newValue)
            }
            .overlay(alignment: .top) {
                UpdateView(proxy: updateViewProxy)
                    .padding(.top)
            }
    }

    // TODO: Better and localize
    @ViewBuilder
    private var loadingView: some View {
        ZStack {
            Color.black

            VStack {
                ProgressView()

                Button {
                    router.dismissCoordinator()
                } label: {
                    Text("Cancel")
                        .foregroundColor(.red)
                }
            }
        }
    }

    var body: some View {
        Group {
            if let viewModel = videoPlayerManager.currentViewModel {
                playerView(with: viewModel)
            } else {
                loadingView
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .ignoresSafeArea()
        .onChange(of: audioOffset) { newValue in
            videoPlayerManager.proxy.setAudioDelay(.ticks(newValue))
        }
        .onChange(of: gestureLocked) { newValue in
            if newValue {
                updateViewProxy.present(systemName: "lock.fill", title: "Gestures Locked")
            } else {
                updateViewProxy.present(systemName: "lock.open.fill", title: "Gestures Unlocked")
            }
        }
        .onChange(of: isScrubbing) { newValue in

            if newValue {
                overlayTimer.stop()
            } else {
                overlayTimer.start(5)
            }

            guard !newValue else { return }
            videoPlayerManager.proxy.setTime(.seconds(currentProgressHandler.scrubbedSeconds))
        }
        .onChange(of: overlayTimer.isActive) { newValue in
            guard !newValue else { return }
            showOverlay(nil)
        }
        .onChange(of: subtitleFontName) { newValue in
            videoPlayerManager.proxy.setSubtitleFont(newValue)
        }
        .onChange(of: subtitleOffset) { newValue in
            videoPlayerManager.proxy.setSubtitleDelay(.ticks(newValue))
        }
        .onChange(of: subtitleSize) { newValue in
            videoPlayerManager.proxy.setSubtitleSize(.absolute(24 - newValue))
        }
        .onChange(of: videoPlayerManager.currentViewModel) { newViewModel in
            guard let newViewModel else { return }
            
            videoPlayerManager.proxy.playNewMedia(newViewModel.vlcVideoPlayerConfiguration)
            
            aspectFilled = false
            audioOffset = 0
            subtitleOffset = 0
        }
    }
    
    private func showOverlay(_ type: OverlayType?) {
        withAnimation(.linear(duration: 0.1)) {
            currentOverlayType = type
        }
    }
}

// MARK: Gestures

extension ItemVideoPlayer {
    
    private func handlePan(
        action: PanAction,
        state: UIGestureRecognizer.State,
        point: CGFloat,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        guard !gestureLocked else { return }
        
        switch action {
        case .none:
            return
        case .audioffset:
            audioOffsetAction(state: state, point: point, velocity: velocity, translation: translation)
        case .brightness:
            brightnessAction(state: state, point: point, velocity: velocity, translation: translation)
        case .playbackSpeed:
            playbackSpeedAction(state: state, point: point, velocity: velocity, translation: translation)
        case .scrub:
            scrubAction(state: state, point: point, velocity: velocity, translation: translation, rate: 1)
        case .slowScrub:
            scrubAction(state: state, point: point, velocity: velocity, translation: translation, rate: 0.1)
        case .subtitleOffset:
            subtitleOffsetAction(state: state, point: point, velocity: velocity, translation: translation)
        case .volume:
            volumeAction(state: state, point: point, velocity: velocity, translation: translation)
        }
    }
    
    private func handleHorizontalSwipe(
        unitPoint: UnitPoint,
        direction: Bool,
        amount: Int
    ) {
        guard !gestureLocked else { return }
        
        switch horizontalSwipeGesture {
        case .none:
            return
        case .jump:
            jumpAction(unitPoint: .init(x: direction ? 1 : 0, y: 0), amount: amount)
        }
    }
    
    private func handleLongPress(point: UnitPoint) {
        switch longPressGesture {
        case .none:
            return
        case .gestureLock:
            guard currentOverlayType == nil else { return }
            gestureLocked.toggle()
        }
    }
    
    private func handlePinchGesture(state: UIGestureRecognizer.State, unitPoint: UnitPoint, scale: CGFloat) {
        guard !gestureLocked else { return }
        
        switch pinchGesture {
        case .none:
            return
        case .aspectFill:
            aspectFillAction(state: state, unitPoint: unitPoint, scale: scale)
        }
    }
    
    private func handleTapGesture(unitPoint: UnitPoint, taps: Int) {
        if gestureLocked {
            updateViewProxy.present(systemName: "lock.fill", title: "Gestures Locked")
            return
        }
        
        if taps > 1 && multiTapGesture != .none {
            switch multiTapGesture {
            case .none:
                return
            case .jump:
                jumpAction(unitPoint: unitPoint, amount: taps - 1)
            }
        } else {
            if currentOverlayType == nil {
                showOverlay(.main)
            } else {
                showOverlay(nil)
            }
        }
    }
}

// MARK: Gesture Actions

// TODO: look at having action changes be separated from the calculations, for incremental jumps vs pans
// TODO: UX polish: small delay (1s) after scrub for isScrubbing = false, only when starting with no overlay

extension ItemVideoPlayer {
    
    private func aspectFillAction(state: UIGestureRecognizer.State, unitPoint: UnitPoint, scale: CGFloat) {
        guard state == .began || state == .changed else { return }
        if scale > 1, !aspectFilled {
            aspectFilled = true
            UIView.animate(withDuration: 0.2) {
                videoPlayerManager.proxy.aspectFill(1)
            }
        } else if scale < 1, aspectFilled {
            aspectFilled = false
            UIView.animate(withDuration: 0.2) {
                videoPlayerManager.proxy.aspectFill(0)
            }
        }
    }
    
    private func audioOffsetAction(
        state: UIGestureRecognizer.State,
        point: CGFloat,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        if state == .began {
            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
            gestureStateHandler.beginningHorizontalPanUnit = point
            gestureStateHandler.beginningAudioOffset = audioOffset
        } else if state == .ended {
            return
        }
        
        let newOffset = gestureStateHandler.beginningAudioOffset - round(Int((gestureStateHandler.beginningHorizontalPanUnit - point) * 2000), toNearest: 100)
        audioOffset = clamp(newOffset, min: -30_000, max: 30_000)
    }
    
    private func brightnessAction(
        state: UIGestureRecognizer.State,
        point: CGFloat,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        if state == .began {
            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
            gestureStateHandler.beginningHorizontalPanUnit = point
            gestureStateHandler.beginningBrightnessValue = UIScreen.main.brightness
        } else if state == .ended {
            return
        }
        
        let newBrightness = gestureStateHandler.beginningBrightnessValue - (gestureStateHandler.beginningHorizontalPanUnit - point)
        let clampedBrightness = clamp(newBrightness, min: 0, max: 1.0)
        let flashPercentage = Int(clampedBrightness * 100)
        
        if flashPercentage >= 67 {
            updateViewProxy.present(systemName: "sun.max.fill", title: "\(flashPercentage)%", iconSize: .init(width: 30, height: 30))
        } else if flashPercentage >= 33 {
            updateViewProxy.present(systemName: "sun.max.fill", title: "\(flashPercentage)%")
        } else {
            updateViewProxy.present(systemName: "sun.min.fill", title: "\(flashPercentage)%", iconSize: .init(width: 20, height: 20))
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            UIScreen.main.brightness = clampedBrightness
        }
    }
    
    // TODO: decide on overlay behavior?
    private func jumpAction(
        unitPoint: UnitPoint,
        amount: Int
    ) {
        if unitPoint.x <= 0.5 {
            videoPlayerManager.proxy.jumpBackward(Int(jumpBackwardLength.rawValue))
            
            updateViewProxy.present(systemName: "gobackward", title: "\(amount * Int(jumpBackwardLength.rawValue))s")
        } else {
            videoPlayerManager.proxy.jumpForward(Int(jumpForwardLength.rawValue))
            
            updateViewProxy.present(systemName: "goforward", title: "\(amount * Int(jumpForwardLength.rawValue))s")
        }
    }
    
    private func playbackSpeedAction(
        state: UIGestureRecognizer.State,
        point: CGFloat,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        if state == .began {
            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
            gestureStateHandler.beginningHorizontalPanUnit = point
            gestureStateHandler.beginningPlaybackSpeed = videoPlayerManager.playbackSpeed
        } else if state == .ended {
            return
        }
        
        let newPlaybackSpeed = round(gestureStateHandler.beginningPlaybackSpeed - Float(gestureStateHandler.beginningHorizontalPanUnit - point) * 2, toNearest: 0.25)
        let clampedPlaybackSpeed = clamp(newPlaybackSpeed, min: 0.25, max: 5.0)
        
        updateViewProxy.present(systemName: "speedometer", title: clampedPlaybackSpeed.rateLabel)
        
        videoPlayerManager.proxy.setRate(.absolute(clampedPlaybackSpeed))
    }
    
    private func scrubAction(
        state: UIGestureRecognizer.State,
        point: CGFloat,
        velocity: CGFloat,
        translation: CGFloat,
        rate: CGFloat
    ) {
        if state == .began {
            isScrubbing = true
            
            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
            gestureStateHandler.beginningHorizontalPanUnit = point
            gestureStateHandler.beganPanWithOverlay = currentOverlayType == .main
        } else if state == .ended {
            if !gestureStateHandler.beganPanWithOverlay {
                showOverlay(nil)
            }
            
            isScrubbing = false
            
            return
        }
        
        let newProgress = gestureStateHandler.beginningPanProgress - (gestureStateHandler.beginningHorizontalPanUnit - point) * rate
        currentProgressHandler.scrubbedProgress = clamp(newProgress, min: 0, max: 1)
    }
    
    private func subtitleOffsetAction(
        state: UIGestureRecognizer.State,
        point: CGFloat,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        if state == .began {
            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
            gestureStateHandler.beginningHorizontalPanUnit = point
            gestureStateHandler.beginningSubtitleOffset = subtitleOffset
        } else if state == .ended {
            return
        }
        
        let newOffset = gestureStateHandler.beginningSubtitleOffset - round(Int((gestureStateHandler.beginningHorizontalPanUnit - point) * 2000), toNearest: 100)
        let clampedOffset = clamp(newOffset, min: -30_000, max: 30_000)
        
        updateViewProxy.present(systemName: "speaker.wave.2.fill", title: clampedOffset.millisecondToSecondLabel)
        
        subtitleOffset = clampedOffset
    }
    
    private func volumeAction(
        state: UIGestureRecognizer.State,
        point: CGFloat,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        let volumeView = MPVolumeView()
        guard let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider else { return }
        
        if state == .began {
            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
            gestureStateHandler.beginningHorizontalPanUnit = point
            gestureStateHandler.beginningVolumeValue = AVAudioSession.sharedInstance().outputVolume
        } else if state == .ended {
            return
        }
        
        let newVolume = gestureStateHandler.beginningVolumeValue - Float(gestureStateHandler.beginningHorizontalPanUnit - point)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider.value = newVolume
        }
    }
}
