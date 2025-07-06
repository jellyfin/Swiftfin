//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import MediaPlayer

import SwiftUI
import VLCUI

// TODO: organize
// TODO: localization necessary for toast text?
// TODO: entire gesture layer should be separate

struct VideoPlayer: View {

    enum OverlayType {
        case main
        case chapters
    }

    @Environment(\.scenePhase)
    private var scenePhase

    class GestureStateHandler {

        var beganPanWithOverlay: Bool = false
        var beginningPanProgress: CGFloat = 0
        var beginningHorizontalPanUnit: CGFloat = 0

        var beginningAudioOffset: Int = 0
        var beginningBrightnessValue: CGFloat = 0
        var beginningPlaybackSpeed: Double = 0
        var beginningSubtitleOffset: Int = 0
        var beginningVolumeValue: Float = 0

        var jumpBackwardKeyPressActive: Bool = false
        var jumpBackwardKeyPressWorkItem: DispatchWorkItem?
        var jumpBackwardKeyPressAmount: Int = 0

        var jumpForwardKeyPressActive: Bool = false
        var jumpForwardKeyPressWorkItem: DispatchWorkItem?
        var jumpForwardKeyPressAmount: Int = 0
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
    @Default(.VideoPlayer.Gesture.doubleTouchGesture)
    private var doubleTouchGesture
    @Default(.VideoPlayer.Gesture.pinchGesture)
    private var pinchGesture
    @Default(.VideoPlayer.Gesture.verticalPanGestureLeft)
    private var verticalGestureLeft
    @Default(.VideoPlayer.Gesture.verticalPanGestureRight)
    private var verticalGestureRight

    @Default(.VideoPlayer.Subtitle.subtitleColor)
    private var subtitleColor
    @Default(.VideoPlayer.Subtitle.subtitleFontName)
    private var subtitleFontName
    @Default(.VideoPlayer.Subtitle.subtitleSize)
    private var subtitleSize

    @Router
    private var router

    @ObservedObject
    private var currentProgressHandler: VideoPlayerManager.CurrentProgressHandler
    @StateObject
    private var splitContentViewProxy: SplitContentViewProxy = .init()
    @ObservedObject
    private var videoPlayerManager: VideoPlayerManager

    @State
    private var audioOffset: Int = 0
    @State
    private var isAspectFilled: Bool = false
    @State
    private var isGestureLocked: Bool = false
    @State
    private var isPresentingOverlay: Bool = false
    @State
    private var isScrubbing: Bool = false
    @State
    private var playbackSpeed: Double = 1
    @State
    private var subtitleOffset: Int = 0

    private let gestureStateHandler: GestureStateHandler = .init()
    private let updateViewProxy: UpdateViewProxy = .init()

    @ViewBuilder
    private var playerView: some View {
        SplitContentView(splitContentWidth: 400)
            .proxy(splitContentViewProxy)
            .content {
                ZStack {
                    VLCVideoPlayer(configuration: videoPlayerManager.currentViewModel.vlcVideoPlayerConfiguration)
                        .proxy(videoPlayerManager.proxy)
                        .onTicksUpdated { ticks, information in

                            let newSeconds = ticks / 1000
                            let newProgress = CGFloat(newSeconds) / CGFloat(videoPlayerManager.currentViewModel.item.runTimeSeconds)
                            currentProgressHandler.progress = newProgress
                            currentProgressHandler.seconds = newSeconds

                            guard !isScrubbing else { return }
                            currentProgressHandler.scrubbedProgress = newProgress

                            videoPlayerManager.onTicksUpdated(
                                ticks: ticks,
                                playbackInformation: information
                            )
                        }
                        .onStateUpdated { state, _ in

                            videoPlayerManager.onStateUpdated(newState: state)

                            if state == .ended {
                                if let _ = videoPlayerManager.nextViewModel,
                                   Defaults[.VideoPlayer.autoPlayEnabled]
                                {
                                    videoPlayerManager.selectNextViewModel()
                                } else {
                                    router.dismiss()
                                }
                            }
                        }

                    GestureView()
                        .onHorizontalPan {
                            handlePan(action: horizontalPanGesture, state: $0, point: $1.x, velocity: $2, translation: $3)
                        }
                        .onHorizontalSwipe(translation: 100, velocity: 1500, sameSwipeDirectionTimeout: 1, handleHorizontalSwipe)
                        .onLongPress(minimumDuration: 2, handleLongPress)
                        .onPinch(handlePinchGesture)
                        .onTap(samePointPadding: 10, samePointTimeout: 0.7, handleTapGesture)
                        .onDoubleTouch(handleDoubleTouchGesture)
                        .onVerticalPan {
                            if $1.x <= 0.5 {
                                handlePan(action: verticalGestureLeft, state: $0, point: -$1.y, velocity: $2, translation: $3)
                            } else {
                                handlePan(action: verticalGestureRight, state: $0, point: -$1.y, velocity: $2, translation: $3)
                            }
                        }

                    VideoPlayer.Overlay()
                }
            }
            .onChange(of: videoPlayerManager.currentProgressHandler.scrubbedProgress) { newValue in
                guard !newValue.isNaN && !newValue.isInfinite else {
                    return
                }
                DispatchQueue.main.async {
                    videoPlayerManager.currentProgressHandler
                        .scrubbedSeconds = Int(CGFloat(videoPlayerManager.currentViewModel.item.runTimeSeconds) * newValue)
                }
            }
            .overlay(alignment: .top) {
                UpdateView(proxy: updateViewProxy)
                    .padding(.top)
            }
            .videoPlayerKeyCommands(
                gestureStateHandler: gestureStateHandler,
                updateViewProxy: updateViewProxy
            )
            .environmentObject(splitContentViewProxy)
            .environmentObject(videoPlayerManager)
            .environmentObject(videoPlayerManager.currentProgressHandler)
            .environmentObject(videoPlayerManager.currentViewModel!)
            .environmentObject(videoPlayerManager.proxy)
            .environment(\.aspectFilled, $isAspectFilled)
            .environment(\.isPresentingOverlay, $isPresentingOverlay)
            .environment(\.isScrubbing, $isScrubbing)
            .environment(\.playbackSpeed, $playbackSpeed)
    }

    var body: some View {
        Group {
            if let _ = videoPlayerManager.currentViewModel {
                playerView
            } else {
                LoadingView()
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .ignoresSafeArea()
        .onAppear {
            // Configure audio session to prevent overload
            VLCVideoPlayer.configureAudioSession()
        }
        .onDisappear {
            // Reset audio session when leaving
            VLCVideoPlayer.resetAudioSession()
        }
        .onChange(of: audioOffset) { newValue in
            Task { @MainActor in
                videoPlayerManager.proxy.setAudioDelay(.ticks(newValue))
            }
        }
        .onChange(of: isAspectFilled) { newValue in
            Task { @MainActor in
                UIView.animate(withDuration: 0.2) {
                    videoPlayerManager.proxy.aspectFill(newValue ? 1 : 0)
                }
            }
        }
        .onChange(of: isGestureLocked) { newValue in
            if newValue {
                updateViewProxy.present(systemName: "lock.fill", title: L10n.gesturesLocked)
            } else {
                updateViewProxy.present(systemName: "lock.open.fill", title: L10n.gesturesUnlocked)
            }
        }
        .onChange(of: isScrubbing) { newValue in
            guard !newValue else { return }
            Task { @MainActor in
                videoPlayerManager.proxy.setTime(.seconds(currentProgressHandler.scrubbedSeconds))
            }
        }
        .onChange(of: subtitleColor) { newValue in
            Task { @MainActor in
                videoPlayerManager.proxy.setSubtitleColor(.absolute(newValue.uiColor))
            }
        }
        .onChange(of: subtitleFontName) { newValue in
            Task { @MainActor in
                videoPlayerManager.proxy.setSubtitleFont(newValue)
            }
        }
        .onChange(of: subtitleOffset) { newValue in
            Task { @MainActor in
                videoPlayerManager.proxy.setSubtitleDelay(.ticks(newValue))
            }
        }
        .onChange(of: subtitleSize) { newValue in
            Task { @MainActor in
                videoPlayerManager.proxy.setSubtitleSize(.absolute(24 - newValue))
            }
        }
        .onChange(of: videoPlayerManager.currentViewModel) { newViewModel in
            guard let newViewModel else { return }

            Task { @MainActor in
                videoPlayerManager.proxy.playNewMedia(newViewModel.vlcVideoPlayerConfiguration)

                isAspectFilled = false
                audioOffset = 0
                subtitleOffset = 0
            }
        }
        .onScenePhase(.active) {
            if Defaults[.VideoPlayer.Transition.playOnActive] {
                Task { @MainActor in
                    videoPlayerManager.proxy.play()
                }
            }
        }
        .onScenePhase(.background) {
            if Defaults[.VideoPlayer.Transition.pauseOnBackground] {
                Task { @MainActor in
                    videoPlayerManager.proxy.pause()
                }
            }
        }
    }
}

extension VideoPlayer {

    init(manager: VideoPlayerManager) {
        self.init(
            currentProgressHandler: manager.currentProgressHandler,
            videoPlayerManager: manager
        )
    }
}

// MARK: Gestures

// TODO: refactor to be split into other files
// TODO: refactor so that actions are separate from the gesture calculations, so that actions are more general

extension VideoPlayer {

    private func handlePan(
        action: PanAction,
        state: UIGestureRecognizer.State,
        point: CGFloat,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        guard !isGestureLocked else { return }

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
        guard !isGestureLocked else { return }

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
            guard !isPresentingOverlay else { return }
            isGestureLocked.toggle()
        }
    }

    private func handlePinchGesture(state: UIGestureRecognizer.State, unitPoint: UnitPoint, scale: CGFloat) {
        guard !isGestureLocked else { return }

        switch pinchGesture {
        case .none:
            return
        case .aspectFill:
            aspectFillAction(state: state, unitPoint: unitPoint, scale: scale)
        }
    }

    private func handleTapGesture(unitPoint: UnitPoint, taps: Int) {
        guard !isGestureLocked else {
            updateViewProxy.present(systemName: "lock.fill", title: L10n.gesturesLocked)
            return
        }

        if taps > 1 && multiTapGesture != .none {

            withAnimation(.linear(duration: 0.1)) {
                isPresentingOverlay = false
            }

            switch multiTapGesture {
            case .none:
                return
            case .jump:
                jumpAction(unitPoint: unitPoint, amount: taps - 1)
            }
        } else {
            withAnimation(.linear(duration: 0.1)) {
                isPresentingOverlay = !isPresentingOverlay
            }
        }
    }

    private func handleDoubleTouchGesture(unitPoint: UnitPoint, taps: Int) {
        if doubleTouchGesture == .gestureLock {
            guard !isPresentingOverlay else { return }
            isGestureLocked.toggle()
        }

        guard !isGestureLocked else {
            updateViewProxy.present(systemName: "lock.fill", title: L10n.gesturesLocked)
            return
        }

        switch doubleTouchGesture {
        case .none:
            return
        case .aspectFill: ()
        case .pausePlay:
            switch videoPlayerManager.state {
            case .playing:
                videoPlayerManager.proxy.pause()
            default:
                videoPlayerManager.proxy.play()
            }
        default:
            break
        }
    }
}

// MARK: Actions

extension VideoPlayer {

    private func aspectFillAction(state: UIGestureRecognizer.State, unitPoint: UnitPoint, scale: CGFloat) {
        guard state == .began || state == .changed else { return }
        if scale > 1, !isAspectFilled {
            isAspectFilled = true
        } else if scale < 1, isAspectFilled {
            isAspectFilled = false
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

        let newOffset = gestureStateHandler.beginningAudioOffset - round(
            Int((gestureStateHandler.beginningHorizontalPanUnit - point) * 2000),
            toNearest: 100
        )

        updateViewProxy.present(systemName: "speaker.wave.2.fill", title: newOffset.millisecondLabel)
        audioOffset = clamp(newOffset, min: -30000, max: 30000)
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
            gestureStateHandler.beginningPlaybackSpeed = playbackSpeed
        } else if state == .ended {
            return
        }

        let newPlaybackSpeed = round(
            gestureStateHandler.beginningPlaybackSpeed - Double(gestureStateHandler.beginningHorizontalPanUnit - point) * 2,
            toNearest: 0.25
        )
        let clampedPlaybackSpeed = clamp(newPlaybackSpeed, min: 0.25, max: 5.0)

        updateViewProxy.present(systemName: "speedometer", title: clampedPlaybackSpeed.rateLabel)

        playbackSpeed = clampedPlaybackSpeed
        videoPlayerManager.proxy.setRate(.absolute(Float(clampedPlaybackSpeed)))
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
            gestureStateHandler.beganPanWithOverlay = isPresentingOverlay
        } else if state == .ended {
            if !gestureStateHandler.beganPanWithOverlay {
                isPresentingOverlay = false
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

        let newOffset = gestureStateHandler.beginningSubtitleOffset - round(
            Int((gestureStateHandler.beginningHorizontalPanUnit - point) * 2000),
            toNearest: 100
        )
        let clampedOffset = clamp(newOffset, min: -30000, max: 30000)

        updateViewProxy.present(systemName: "captions.bubble.fill", title: clampedOffset.millisecondLabel)

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
