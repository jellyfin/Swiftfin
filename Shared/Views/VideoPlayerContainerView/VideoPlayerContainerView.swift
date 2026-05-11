//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Engine
import Logging
import MediaPlayer
import SwiftUI

// TODO: don't dismiss overlay while panning and supplement not presented
// TODO: use video size from proxies to control aspect fill
//       - stay within safe areas, aspect fill to screen
// TODO: instead of static sizes for supplement view, take into account available space
//       - necessary for full-screen supplements and/or small screens
// TODO: custom buttons on playback controls
//       - skip intro, next episode, etc.
//       - can just do on playback controls itself
// TODO: pass in safe area insets explicitly?
// TODO: pause when center tapped when overlay dismissed
//       - can be done entirely on playback controls layer
// TODO: no supplements state
//       - don't pan
// TODO: account for gesture state active when item changes
// TODO: only show player view if not error/other bad states
//       - only show when have item?
//       - helps with not rendering before ready
//       - would require refactor so that video players take media player items

// MARK: - VideoPlayerContainerView

extension VideoPlayer {
    struct VideoPlayerContainerView<Player: View, PlaybackControls: View>: UIViewControllerRepresentable {

        private let containerState: VideoPlayerContainerState
        private let manager: MediaPlayerManager
        private let player: () -> Player
        private let playbackControls: () -> PlaybackControls

        init(
            containerState: VideoPlayerContainerState,
            manager: MediaPlayerManager,
            @ViewBuilder player: @escaping () -> Player,
            @ViewBuilder playbackControls: @escaping () -> PlaybackControls
        ) {
            self.containerState = containerState
            self.manager = manager
            self.player = player
            self.playbackControls = playbackControls
        }

        func makeUIViewController(context: Context) -> UIVideoPlayerContainerViewController {
            let playerView = player()
                .environment(\.audioOffset, context.environment.audioOffset)
                .eraseToAnyView()
            let playbackControlsView = playbackControls()
                .environment(\.audioOffset, context.environment.audioOffset)
                .eraseToAnyView()

            return UIVideoPlayerContainerViewController(
                containerState: containerState,
                manager: manager,
                player: playerView,
                playbackControls: playbackControlsView
            )
        }

        func updateUIViewController(
            _ uiViewController: UIVideoPlayerContainerViewController,
            context: Context
        ) {}
    }

    // MARK: - UIVideoPlayerContainerViewController

    class UIVideoPlayerContainerViewController: UIViewController {

        // MARK: - Views

        // TODO: preview image while scrubbing option
        private struct PlayerContainerView: View {

            @EnvironmentObject
            private var containerState: VideoPlayerContainerState

            let player: AnyView

            private var shouldPresentDimOverlay: Bool {
                if containerState.isScrubbing {
                    return false
                }

                if containerState.isCompact {
                    return containerState.isPresentingPlaybackControls
                } else {
                    return containerState.isPresentingOverlay
                }
            }

            var body: some View {
                player
                    .overlay(Color.black.opacity(shouldPresentDimOverlay ? 0.5 : 0.0))
                    .animation(.linear(duration: 0.2), value: containerState.isPresentingPlaybackControls)
                    .allowsHitTesting(false)
            }
        }

        private struct PlaybackControlsContainerView: View {

            @EnvironmentObject
            private var containerState: VideoPlayerContainerState

            let playbackControls: AnyView

            var body: some View {
                OverlayToastView(proxy: containerState.toastProxy) {
                    Group {
                        #if os(iOS)
                        ZStack {
                            GestureView()
                                .environment(
                                    \.panGestureDirection,
                                    containerState.presentationControllerShouldDismiss ? .allButDown : .vertical
                                )

                            playbackControls
                        }
                        #else
                        playbackControls
                        #endif
                    }
                    .environmentObject(containerState.scrubbedSeconds)
                }
                #if os(iOS)
                .environment(
                    \.longPressAction,
                    .init(
                        action: {
                            containerState.containerView?.handleLongPressGesture(
                                location: $0,
                                unitPoint: $1,
                                state: $2
                            )
                        }
                    )
                )
                .environment(
                    \.panAction,
                    .init(
                        action: {
                            containerState.containerView?.handlePanGesture(
                                translation: $0,
                                velocity: $1,
                                location: $2,
                                unitPoint: $3,
                                state: $4
                            )
                        }
                    )
                )
                .environment(
                    \.pinchAction,
                    .init(
                        action: {
                            containerState.containerView?.handlePinchGesture(scale: $0, velocity: $1, state: $2)
                        }
                    )
                )
                .environment(
                    \.tapGestureAction,
                    .init(
                        action: {
                            containerState.containerView?.handleTapGesture(
                                location: $0,
                                unitPoint: $1,
                                count: $2
                            )
                        }
                    )
                )
                #endif
            }
        }

        private lazy var initialHitBlockView: UIView = {
            let view = UIView(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()

        private lazy var playerViewController: HostingController<AnyView> = {
            let controller = HostingController(
                content: PlayerContainerView(player: player)
                    .environmentObject(containerState)
                    .environmentObject(manager)
                    .eraseToAnyView()
            )
            controller.disablesSafeArea = true
            controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            return controller
        }()

        private lazy var playbackControlsViewController: HostingController<AnyView> = {
            let controller = HostingController(
                content: PlaybackControlsContainerView(playbackControls: playbackControls)
                    .environmentObject(containerState)
                    .environmentObject(manager)
                    .eraseToAnyView()
            )
            controller.disablesSafeArea = true
            controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            return controller
        }()

        private lazy var supplementContainerViewController: HostingController<AnyView> = {
            let content = SupplementContainerView()
                .environmentObject(containerState)
                .environmentObject(manager)
                .eraseToAnyView()
            let controller = HostingController(content: content)
            controller.disablesSafeArea = true
            controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            return controller
        }()

        private var playerView: UIView {
            playerViewController.view
        }

        private var playbackControlsView: UIView {
            playbackControlsViewController.view
        }

        private var supplementContainerView: UIView {
            supplementContainerViewController.view
        }

        // MARK: - Constants

        private let compactSupplementContainerOffset: (CGFloat) -> CGFloat = { totalHeight in
            max(totalHeight * 0.6, 300) + EdgeInsets.edgePadding * 2
        }

        private var regularSupplementContainerOffset: CGFloat {
            if UIDevice.isTV {
                view.bounds.height / 3 + EdgeInsets.edgePadding * 2
            } else {
                200.0 + EdgeInsets.edgePadding * 2
            }
        }

        private var dismissedSupplementContainerOffset: CGFloat {
            UIDevice.isTV ? 120 : 50.0 + EdgeInsets.edgePadding * 2
        }

        private let compactMinimumTranslation: CGFloat = 100.0
        private let regularMinimumTranslation: CGFloat = 50.0

        // MARK: - Constraints

        private var playbackControlsConstraints: [NSLayoutConstraint] = []
        private var playerCompactConstraints: [NSLayoutConstraint] = []
        private var playerRegularConstraints: [NSLayoutConstraint] = []
        private var supplementContainerConstraints: [NSLayoutConstraint] = []

        private var playerCompactBottomAnchor: NSLayoutConstraint?
        private var supplementHeightAnchor: NSLayoutConstraint?
        private var supplementBottomAnchor: NSLayoutConstraint?

        private var centerOffset: CGFloat {
            guard containerState.isCompact, let supplementBottomAnchor else {
                return dismissedSupplementContainerOffset
            }

            let supplementContainerHeight = compactSupplementContainerOffset(view.bounds.height)
            let offsetPercentage = 1 - clamp(supplementBottomAnchor.constant.magnitude / supplementContainerHeight, min: 0, max: 1)
            let offset = (dismissedSupplementContainerOffset + EdgeInsets.edgePadding) * offsetPercentage

            return max(50, offset)
        }

        private var compactPlayerBottomOffset: CGFloat {
            guard containerState.isCompact, let supplementBottomAnchor else {
                return dismissedSupplementContainerOffset
            }
            let supplementContainerHeight = compactSupplementContainerOffset(view.bounds.height)
            let offsetPercentage = 1 - clamp(supplementBottomAnchor.constant.magnitude / supplementContainerHeight, min: 0, max: 1)
            return (dismissedSupplementContainerOffset + EdgeInsets.edgePadding) * offsetPercentage
        }

        private let logger = Logger.swiftfin()
        private let manager: MediaPlayerManager
        private let player: AnyView
        private let playbackControls: AnyView
        let containerState: VideoPlayerContainerState

        private var cancellables: Set<AnyCancellable> = []
        private var didInitiallyAppear: Bool = false

        #if os(tvOS)
        let onPressEvent = OnPressEvent()
        private var lastTouchPokeTime: CFTimeInterval = 0
        #endif

        init(
            containerState: VideoPlayerContainerState,
            manager: MediaPlayerManager,
            player: AnyView,
            playbackControls: AnyView
        ) {
            self.containerState = containerState
            self.manager = manager
            self.player = player
            self.playbackControls = playbackControls

            super.init(nibName: nil, bundle: nil)

            containerState.containerView = self
            containerState.manager = manager
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // TODO: don't force unwrap optional, sometimes gets into weird state
        private var lastVerticalPanLocation: CGPoint?
        private var verticalPanGestureStartConstant: CGFloat?
        private var isPanning: Bool = false
        private var didStartPanningWithSupplement: Bool = false
        private var didStartPanningUpWithoutOverlay: Bool = false

        // MARK: - Supplement Pan Action

        func handleSupplementPanAction(
            translation: CGPoint,
            velocity: CGFloat,
            location: CGPoint,
            state: UIGestureRecognizer.State
        ) {
            guard let supplementBottomAnchor, let playerCompactBottomAnchor else { return }

            let yDirection: CGFloat = translation.y > 0 ? -1 : 1
            let newOffset: CGFloat
            let clampedOffset: CGFloat

            if state == .began {
                self.view.layer.removeAllAnimations()
                didStartPanningWithSupplement = containerState.selectedSupplement != nil
                verticalPanGestureStartConstant = supplementBottomAnchor.constant
                didStartPanningUpWithoutOverlay = !containerState.isPresentingOverlay
                if didStartPanningUpWithoutOverlay {
                    containerState.isPresentingOverlay = true
                }
            }

            if state == .began || state == .changed {
                lastVerticalPanLocation = location
                isPanning = true

                let minimumTranslation =
                    -((containerState.isCompact ? compactMinimumTranslation : regularMinimumTranslation) +
                        dismissedSupplementContainerOffset
                    )
                let shouldHaveSupplementPresented = supplementBottomAnchor.constant < minimumTranslation

                if shouldHaveSupplementPresented, !containerState.isPresentingSupplement {
                    containerState.selectedSupplement = manager.supplements.first
                } else if !shouldHaveSupplementPresented, containerState.selectedSupplement != nil {
                    containerState.selectedSupplement = nil
                }
            } else {
                lastVerticalPanLocation = nil
                verticalPanGestureStartConstant = nil
                isPanning = false

                let translationMin: CGFloat = containerState.isCompact ? compactMinimumTranslation : regularMinimumTranslation
                let shouldActuallyDismissSupplement = didStartPanningWithSupplement && (translation.y > translationMin || velocity > 1000)
                if shouldActuallyDismissSupplement {
                    // If we started with a supplement and panned down more than 100 points, dismiss it
                    containerState.selectedSupplement = nil
                }

                let shouldActuallyPresentSupplement = !didStartPanningWithSupplement &&
                    (translation.y < -translationMin || velocity < -1000)
                if shouldActuallyPresentSupplement {
                    // If we didn't start with a supplement and panned up more than 100 points, present it
                    containerState.selectedSupplement = manager.supplements.first
                }

                let stateToPass: (translation: CGFloat, velocity: CGFloat)? = lastVerticalPanLocation != nil &&
                    verticalPanGestureStartConstant !=
                    nil ?
                    (translation: translation.y, velocity: velocity) : nil
                presentSupplementContainer(containerState.selectedSupplement != nil, with: stateToPass)

                let shouldActuallyDismissOverlay = didStartPanningUpWithoutOverlay && !containerState.isPresentingSupplement

                if shouldActuallyDismissOverlay {
                    containerState.isPresentingOverlay = false
                }
                return
            }

            guard let verticalPanGestureStartConstant else {
                logger.error("Vertical pan gesture invalid state: verticalPanGestureStartConstant is nil")
                return
            }

            if (!didStartPanningWithSupplement && yDirection > 0) || (didStartPanningWithSupplement && yDirection < 0) {
                // If we started with a supplement and are panning down, or if we didn't start with a supplement and are panning up
                newOffset = verticalPanGestureStartConstant + (translation.y.magnitude * -yDirection)
            } else {
                newOffset = verticalPanGestureStartConstant - (translation.y.magnitude * yDirection)
            }

            if containerState.isCompact {
                clampedOffset = clamp(
                    newOffset,
                    min: -compactSupplementContainerOffset(view.bounds.height),
                    max: -dismissedSupplementContainerOffset
                )
            } else {
                clampedOffset = clamp(
                    newOffset,
                    min: -regularSupplementContainerOffset,
                    max: -dismissedSupplementContainerOffset
                )
            }

            if newOffset < clampedOffset {
                let excess = clampedOffset - newOffset
                let resistance = pow(excess, 0.7)
                supplementBottomAnchor.constant = clampedOffset - resistance
            } else if newOffset > -dismissedSupplementContainerOffset {
                let excess = newOffset - clampedOffset
                let resistance = pow(excess, 0.5)
                supplementBottomAnchor.constant = clamp(clampedOffset + resistance, min: -dismissedSupplementContainerOffset, max: -50)
            } else {
                supplementBottomAnchor.constant = clampedOffset
            }

            playerCompactBottomAnchor.constant = compactPlayerBottomOffset
            containerState.centerOffset = centerOffset
        }

        // MARK: - present

        func presentSupplementContainer(
            _ didPresent: Bool,
            with panningState: (translation: CGFloat, velocity: CGFloat)? = nil
        ) {
            guard !isPanning else { return }
            guard let supplementBottomAnchor, let playerCompactBottomAnchor else { return }

            if didPresent {
                if containerState.isCompact {
                    supplementBottomAnchor.constant = -compactSupplementContainerOffset(view.bounds.size.height)
                } else {
                    supplementBottomAnchor.constant = -regularSupplementContainerOffset
                }
            } else {
                supplementBottomAnchor.constant = -dismissedSupplementContainerOffset
            }

            playerCompactBottomAnchor.constant = compactPlayerBottomOffset
            containerState.centerOffset = centerOffset

            if let panningState {
                let velocity = panningState.velocity.magnitude / 1000
                let distance = panningState.translation.magnitude
                let duration = min(max(Double(distance) / Double(velocity * 1000), 0.2), 0.75)

                UIView.animate(
                    withDuration: duration,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: velocity,
                    options: .allowUserInteraction
                ) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            } else {
                UIView.animate(
                    withDuration: containerState.isCompact ? 0.75 : 0.6,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0.4,
                    options: .allowUserInteraction
                ) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            }
        }

        // MARK: - viewDidAppear

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            if !didInitiallyAppear {
                containerState.isPresentingOverlay = true
                setupPlayerView()
                initialHitBlockView.removeFromSuperview()
                didInitiallyAppear = true
            }

            #if os(tvOS)
            Task { @MainActor in
                disableTogglePlayPauseCommand()
            }
            #endif
        }

        // MARK: - viewDidLoad

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .black

            let isCompact = UIDevice.isPhone && view.bounds.size.isPortrait

            setupOnLoadViews()
            setupOnLoadConstraints()

            Task { @MainActor in
                containerState.isCompact = isCompact
                containerState.centerOffset = centerOffset
            }

            #if os(tvOS)
            let gesture = UITapGestureRecognizer(target: self, action: #selector(menuPressed))
            gesture.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
            view.addGestureRecognizer(gesture)

            containerState.$isPresentingOverlay
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isPresenting in
                    self?.supplementContainerView.isUserInteractionEnabled = isPresenting
                }
                .store(in: &cancellables)
            #endif
        }

        // Setup player view separately after view appears to hopefully
        // prevent player playing before the view is done presenting
        private func setupPlayerView() {
            addChild(playerViewController)
            view.addSubview(playerView)
            view.sendSubviewToBack(playerView)
            playerViewController.didMove(toParent: self)
            playerView.backgroundColor = .black

            let bottomAnchor = playerView.bottomAnchor.constraint(
                equalTo: supplementContainerView.topAnchor,
                constant: compactPlayerBottomOffset
            )

            playerCompactBottomAnchor = bottomAnchor

            playerCompactConstraints = [
                playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerView.topAnchor.constraint(equalTo: view.topAnchor),
                bottomAnchor,
            ]
            playerRegularConstraints = [
                playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerView.topAnchor.constraint(equalTo: view.topAnchor),
                playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]

            if containerState.isCompact {
                NSLayoutConstraint.activate(playerCompactConstraints)
            } else {
                NSLayoutConstraint.activate(playerRegularConstraints)
            }
        }

        private func setupOnLoadViews() {
            addChild(playbackControlsViewController)
            view.addSubview(playbackControlsView)
            playbackControlsViewController.didMove(toParent: self)
            playbackControlsView.backgroundColor = .clear

            addChild(supplementContainerViewController)
            view.addSubview(supplementContainerView)
            supplementContainerViewController.didMove(toParent: self)
            supplementContainerView.backgroundColor = .clear

            view.addSubview(initialHitBlockView)
            view.bringSubviewToFront(initialHitBlockView)
        }

        private func setupOnLoadConstraints() {

            let isCompact = UIDevice.isPhone && view.bounds.size.isPortrait

            let bottomAnchor = supplementContainerView.topAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -dismissedSupplementContainerOffset
            )
            supplementBottomAnchor = bottomAnchor

            let constant = isCompact ?
                compactSupplementContainerOffset(view.bounds.height) :
                regularSupplementContainerOffset
            let heightAnchor = supplementContainerView.heightAnchor.constraint(equalToConstant: constant)
            supplementHeightAnchor = heightAnchor

            supplementContainerConstraints = [
                supplementContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                supplementContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomAnchor,
                heightAnchor,
            ]

            NSLayoutConstraint.activate(supplementContainerConstraints)

            playbackControlsConstraints = [
                playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playbackControlsView.topAnchor.constraint(equalTo: view.topAnchor),
                playbackControlsView.bottomAnchor.constraint(equalTo: supplementContainerView.topAnchor),
            ]

            NSLayoutConstraint.activate(playbackControlsConstraints)

            NSLayoutConstraint.activate([
                initialHitBlockView.topAnchor.constraint(equalTo: view.topAnchor),
                initialHitBlockView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                initialHitBlockView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                initialHitBlockView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            adjustContraints(isCompact: UIDevice.isPhone && size.isPortrait, in: size)
        }

        private func adjustContraints(isCompact: Bool, in newSize: CGSize) {
            containerState.isCompact = isCompact

            guard let supplementBottomAnchor,
                  let supplementHeightAnchor,
                  let playerCompactBottomAnchor
            else { return }

            if isCompact {
                NSLayoutConstraint.deactivate(playerRegularConstraints)
                NSLayoutConstraint.activate(playerCompactConstraints)

                supplementBottomAnchor.constant = containerState
                    .isPresentingSupplement ? -compactSupplementContainerOffset(newSize.height) : -dismissedSupplementContainerOffset
                supplementHeightAnchor.constant = compactSupplementContainerOffset(newSize.height)
            } else {
                NSLayoutConstraint.deactivate(playerCompactConstraints)
                NSLayoutConstraint.activate(playerRegularConstraints)

                supplementBottomAnchor.constant = containerState
                    .isPresentingSupplement ? -regularSupplementContainerOffset : -dismissedSupplementContainerOffset
                supplementHeightAnchor.constant = regularSupplementContainerOffset
            }

            playerCompactBottomAnchor.constant = compactPlayerBottomOffset
            containerState.centerOffset = centerOffset
        }

        // MARK: - tvOS

        #if os(tvOS)
        /// Handle view disappearance since tvOS this can be done in non-standard ways
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            guard manager.state != .stopped else { return }

            Task { @MainActor in
                manager.stop()
            }
        }

        private func disableTogglePlayPauseCommand() {
            let cmd = MPRemoteCommandCenter.shared().togglePlayPauseCommand
            cmd.removeTarget(nil)
            cmd.addTarget { _ in .success }
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)

            let now = CACurrentMediaTime()
            guard now - lastTouchPokeTime > 1.0 else { return }
            lastTouchPokeTime = now

            if !containerState.isPresentingOverlay {
                containerState.isPresentingOverlay = true
            } else {
                containerState.timer.poke()
            }
        }

        @objc
        private func menuPressed() {
            handleMenuEnded()
        }

        private func forwardPressesBegan(
            _ presses: Set<UIPress>,
            event: UIPressesEvent?
        ) {
            super.pressesBegan(presses, with: event)
        }

        private func forwardPressesEnded(
            _ presses: Set<UIPress>,
            event: UIPressesEvent?
        ) {
            super.pressesEnded(presses, with: event)
        }

        override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            for press in presses {
                switch press.type {
                case .playPause, .select, .menu:
                    continue
                default:
                    let defaultAction: () -> Void = { [weak self] in
                        guard let self else { return }
                        self.forwardPressesBegan([press], event: event)
                    }

                    onPressEvent.send(
                        .init(
                            type: press.type,
                            phase: press.phase,
                            performDefault: defaultAction
                        )
                    )
                }
            }
        }

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            for press in presses {
                switch press.type {
                case .playPause:
                    handlePlayPauseEnded()
                case .select:
                    handleSelectEnded(press, event: event)
                case .menu:
                    handleMenuEnded()
                default:
                    let defaultAction: () -> Void = { [weak self] in
                        guard let self else { return }
                        self.forwardPressesEnded([press], event: event)
                    }

                    onPressEvent.send(
                        .init(
                            type: press.type,
                            phase: press.phase,
                            performDefault: defaultAction
                        )
                    )
                }
            }
        }

        private func handlePlayPauseEnded() {
            if containerState.hasEnteredScrubMode {
                containerState.cancelScrub()
                containerState.timer.poke()
                return
            }

            if !containerState.isPresentingOverlay {
                if manager.playbackRequestStatus == .paused {
                    manager.setPlaybackRequestStatus(status: .playing)
                }
                containerState.isPresentingOverlay = true
            } else {
                switch manager.playbackRequestStatus {
                case .playing:
                    manager.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    manager.setPlaybackRequestStatus(status: .playing)
                }
            }
            containerState.timer.poke()
        }

        private func handleSelectEnded(_ press: UIPress, event: UIPressesEvent?) {
            if !containerState.isPresentingOverlay {
                containerState.isPresentingOverlay = true
                containerState.timer.poke()
                return
            }

            if containerState.hasEnteredScrubMode {
                containerState.commitScrub()
                containerState.timer.poke()
            } else if containerState.isProgressBarFocused {
                switch manager.playbackRequestStatus {
                case .playing:
                    manager.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    manager.setPlaybackRequestStatus(status: .playing)
                }
                containerState.timer.poke()
            } else {
                forwardPressesEnded([press], event: event)
            }
        }

        private func handleMenuEnded() {
            if containerState.hasEnteredScrubMode {
                containerState.cancelScrub()
                containerState.timer.poke()
            } else if containerState.isPresentingSupplement {
                containerState.selectedSupplement = nil
                presentSupplementContainer(false)
                containerState.isProgressBarFocused = true
                containerState.timer.poke()
            } else if containerState.isPresentingOverlay {
                containerState.isPresentingOverlay = false
            } else {
                containerState.isPresentingCloseConfirmation = true
            }
        }
        #endif
    }
}

// MARK: - tvOS PressEvent

#if os(tvOS)
extension VideoPlayer.UIVideoPlayerContainerViewController {

    struct PressEvent {

        enum Resolution {
            case handled
            case fallback
        }

        let type: UIPress.PressType
        let phase: UIPress.Phase

        fileprivate let performDefault: () -> Void

        func resolve(_ resolution: Resolution) {
            if resolution == .fallback {
                performDefault()
            }
        }
    }

    typealias OnPressEvent = LegacyEventPublisher<PressEvent>
}
#endif
