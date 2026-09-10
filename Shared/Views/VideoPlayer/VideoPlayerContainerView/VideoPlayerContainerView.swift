//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
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

#if !os(macOS)
extension VideoPlayer {

    struct VideoPlayerContainerView<Player: View, PlaybackControls: View>: PlatformViewControllerRepresentable {

        private let containerState: VideoPlayerContainerState
        private let manager: MediaPlayerManager
        private let player: Player
        private let playbackControls: PlaybackControls

        init(
            containerState: VideoPlayerContainerState,
            manager: MediaPlayerManager,
            @ViewBuilder player: @escaping () -> Player,
            @ViewBuilder playbackControls: @escaping () -> PlaybackControls
        ) {
            self.containerState = containerState
            self.manager = manager
            self.player = player()
            self.playbackControls = playbackControls()
        }

        func makeUIViewController(context: Context) -> UIVideoPlayerContainerViewController {
            let playerView = player
                .environment(\.audioOffset, context.environment.audioOffset)
                .eraseToAnyView()

            let playbackControlsView = playbackControls
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

            private var presentedSupplementStyle: MediaPlayerSupplementPresentationStyle? {
                #if os(tvOS)
                containerState.presentedSupplementStyle
                #else
                containerState.selectedSupplement?.presentationStyle
                #endif
            }

            var body: some View {
                player
                #if os(iOS)
                .overlay(Color.black.opacity(shouldPresentDimOverlay ? 0.5 : 0.0))
                #endif
                .overlay {
                    Group {
                        if presentedSupplementStyle == .expanded {
                            Color.black.opacity(0.8)
                        } else {
                            EasedGradient(
                                colors: [.clear, .black],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        }
                    }
                    .isVisible(shouldPresentDimOverlay)
                }
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
                                    containerState.isPresentingSupplement
                                        ? .vertical
                                        : (containerState.isPresentingOverlay ? .up : .allButDown)
                                )

                            playbackControls
                        }
                        #else
                        playbackControls
                        #endif
                    }
                    .environmentObject(containerState.scrubbedSeconds)
                    .environmentObject(containerState.centerOffsetBox)
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
            controller.disableSafeArea = true
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
            controller.disableSafeArea = true
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
            controller.disableSafeArea = true
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

        private func regularSupplementContainerOffset(_ totalHeight: CGFloat) -> CGFloat {
            if UIDevice.isTV {
                totalHeight / 3 + EdgeInsets.edgePadding * 2
            } else {
                200.0 + EdgeInsets.edgePadding * 2
            }
        }

        private func supplementContainerOffset(
            for totalHeight: CGFloat,
            isCompact: Bool? = nil
        ) -> CGFloat {
            let isCompact = isCompact ?? containerState.isCompact
            let regularOffset = isCompact
                ? compactSupplementContainerOffset(totalHeight)
                : regularSupplementContainerOffset(totalHeight)

            guard !isCompact,
                  presentedSupplementStyle == .expanded
            else {
                return regularOffset
            }

            return totalHeight
        }

        private var presentedSupplementStyle: MediaPlayerSupplementPresentationStyle? {
            #if os(tvOS)
            containerState.presentedSupplementStyle
            #else
            containerState.selectedSupplement?.presentationStyle
            #endif
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
            guard containerState.isCompact,
                  let supplementBottomAnchor,
                  let supplementHeightAnchor
            else {
                return dismissedSupplementContainerOffset
            }

            let supplementContainerHeight = supplementHeightAnchor.constant
            let offsetPercentage = 1 - clamp(supplementBottomAnchor.constant.magnitude / supplementContainerHeight, min: 0, max: 1)
            let offset = (dismissedSupplementContainerOffset + EdgeInsets.edgePadding) * offsetPercentage

            return max(50, offset)
        }

        private var compactPlayerBottomOffset: CGFloat {
            guard containerState.isCompact,
                  let supplementBottomAnchor,
                  let supplementHeightAnchor
            else {
                return dismissedSupplementContainerOffset
            }
            let supplementContainerHeight = supplementHeightAnchor.constant
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
            guard let supplementBottomAnchor,
                  let supplementHeightAnchor,
                  let playerCompactBottomAnchor
            else { return }

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

            clampedOffset = clamp(
                newOffset,
                min: -supplementHeightAnchor.constant,
                max: -dismissedSupplementContainerOffset
            )

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
            containerState.centerOffsetBox.value = centerOffset
        }

        // MARK: - present

        func presentSupplementContainer(
            _ didPresent: Bool,
            with panningState: (translation: CGFloat, velocity: CGFloat)? = nil,
            presentationStyle: MediaPlayerSupplementPresentationStyle? = nil
        ) {
            guard !isPanning else { return }
            guard let supplementBottomAnchor,
                  let supplementHeightAnchor,
                  let playerCompactBottomAnchor
            else { return }

            #if os(tvOS)
            if !didPresent || presentationStyle != nil {
                containerState.setPresentedSupplementStyle(didPresent ? presentationStyle : nil)
            }
            #endif

            if didPresent {
                let presentedOffset = supplementContainerOffset(for: view.bounds.height)
                supplementHeightAnchor.constant = presentedOffset
                supplementBottomAnchor.constant = -presentedOffset
            } else {
                supplementBottomAnchor.constant = -dismissedSupplementContainerOffset
            }

            playerCompactBottomAnchor.constant = compactPlayerBottomOffset
            containerState.centerOffsetBox.value = centerOffset

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
                containerState.centerOffsetBox.value = centerOffset
            }

            #if os(tvOS)
            let gesture = UITapGestureRecognizer(target: self, action: #selector(handleMenuEnded))
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

            let constant = supplementContainerOffset(
                for: view.bounds.height,
                isCompact: isCompact
            )
            let heightAnchor = supplementContainerView.heightAnchor.constraint(equalToConstant: constant)
            supplementHeightAnchor = heightAnchor

            supplementContainerConstraints = [
                supplementContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                supplementContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomAnchor,
                heightAnchor,
            ]

            NSLayoutConstraint.activate(supplementContainerConstraints)

            #if os(tvOS)
            let playbackControlsBottomAnchor = playbackControlsView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -dismissedSupplementContainerOffset
            )
            #else
            let playbackControlsBottomAnchor = playbackControlsView.bottomAnchor.constraint(
                equalTo: supplementContainerView.topAnchor
            )
            #endif

            playbackControlsConstraints = [
                playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playbackControlsView.topAnchor.constraint(equalTo: view.topAnchor),
                playbackControlsBottomAnchor,
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

            let presentedOffset = supplementContainerOffset(
                for: newSize.height,
                isCompact: isCompact
            )

            if isCompact {
                NSLayoutConstraint.deactivate(playerRegularConstraints)
                NSLayoutConstraint.activate(playerCompactConstraints)
            } else {
                NSLayoutConstraint.deactivate(playerCompactConstraints)
                NSLayoutConstraint.activate(playerRegularConstraints)
            }

            supplementBottomAnchor.constant = containerState
                .isPresentingSupplement ? -presentedOffset : -dismissedSupplementContainerOffset
            supplementHeightAnchor.constant = presentedOffset

            playerCompactBottomAnchor.constant = compactPlayerBottomOffset
            containerState.centerOffsetBox.value = centerOffset
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
            let command = MPRemoteCommandCenter.shared().togglePlayPauseCommand
            command.removeTarget(nil)
            command.addTarget { _ in .success }
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
                            defaultAction: defaultAction
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
                            defaultAction: defaultAction
                        )
                    )
                }
            }
        }

        private func handlePlayPauseEnded() {
            if containerState.isScrubbing {
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

            if containerState.isScrubbing {
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

        @objc
        private func handleMenuEnded() {
            if containerState.isScrubbing {
                containerState.cancelScrub()
                containerState.timer.poke()
            } else if containerState.isPresentingSupplement {
                containerState.selectedSupplement = nil
                presentSupplementContainer(false)
                containerState.isProgressBarFocused = true
                containerState.timer.poke()
            } else if containerState.isPresentingOverlay {
                containerState.isPresentingOverlay = false
            } else if Defaults[.confirmClose] {
                containerState.isPresentingCloseConfirmation = true
            } else {
                manager.stop()
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

        fileprivate let defaultAction: () -> Void

        func resolve(_ resolution: Resolution) {
            if resolution == .fallback {
                defaultAction()
            }
        }
    }

    typealias OnPressEvent = EventPublisher<PressEvent>
}
#endif
#else
extension VideoPlayer {

    struct VideoPlayerContainerView<Player: View, PlaybackControls: View>: View {

        @ObservedObject
        private var containerState: VideoPlayerContainerState
        @ObservedObject
        private var manager: MediaPlayerManager
        private let player: Player
        private let playbackControls: PlaybackControls

        @State
        private var lastHoverLocation: CGPoint = .zero

        init(
            containerState: VideoPlayerContainerState,
            manager: MediaPlayerManager,
            @ViewBuilder player: @escaping () -> Player,
            @ViewBuilder playbackControls: @escaping () -> PlaybackControls
        ) {
            self.containerState = containerState
            self.manager = manager
            self.player = player()
            self.playbackControls = playbackControls()
            containerState.manager = manager
        }

        private var isPresentingControls: Bool {
            containerState.isPresentingOverlay || containerState.isPresentingPlaybackControls
        }

        /// Reveals the overlay and restarts the auto-hide countdown.
        ///
        /// `isPresentingOverlay` republishes on same-value writes, so a plain
        /// assignment on every mouse-move event would rebuild the overlay
        /// continuously. Only write when the value actually changes.
        private func revealControls() {
            MacWindowState.shared.setCursorHidden(false)

            guard !containerState.isPresentingOverlay else {
                containerState.timer.poke()
                return
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                containerState.isPresentingOverlay = true
            }
        }

        private func handleHover(_ phase: HoverPhase) {
            guard case let .active(location) = phase else { return }

            // SwiftUI emits hover events during layout, which would otherwise
            // keep poking the timer and the overlay would never auto-hide.
            let delta = hypot(
                location.x - lastHoverLocation.x,
                location.y - lastHoverLocation.y
            )
            guard delta > 2 else { return }

            lastHoverLocation = location
            revealControls()
        }

        var body: some View {
            OverlayToastView(proxy: containerState.toastProxy) {
                ZStack {
                    player
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)

                    // The VLC drawable is an AppKit view, so it hit-tests
                    // before any gesture attached to an ancestor of the stack.
                    // Catch clicks on a layer stacked above it instead, and
                    // keep it below the controls so buttons still win.
                    //
                    // A single un-composed tap on purpose: pairing it with a
                    // double-tap recognizer leaves the single tap waiting on a
                    // failure that never arrives, so no click registers at all.
                    // Full screen stays on its own button, the green traffic
                    // light, and the standard system shortcut.
                    Color.clear
                        .contentShape(Rectangle())
                        .onContinuousHover(perform: handleHover)
                        .onTapGesture {
                            guard !containerState.isPresentingSupplement else { return }
                            revealControls()
                            manager.togglePlayPause()
                        }

                    if containerState.isPresentingSupplement {
                        UIVideoPlayerContainerViewController.SupplementContainerView()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if isPresentingControls {
                        playbackControls
                            .transition(.opacity)
                    }
                }
                // `PlaybackButtons`, `PlaybackProgress` and the supplements read
                // these boxes as environment objects. Omitting them traps at
                // runtime the moment the overlay is presented.
                .environmentObject(containerState.scrubbedSeconds)
                .environmentObject(containerState.centerOffsetBox)
            }
            .background(Color.black)
            .clipped()
            .onChange(of: containerState.isPresentingOverlay) {
                MacWindowState.shared.setCursorHidden(!containerState.isPresentingOverlay)
            }
            .onAppear {
                // Mirrors the UIKit container's `viewDidAppear`: start with the
                // controls visible so playback never opens to a bare surface.
                containerState.isPresentingOverlay = true
            }
            .onDisappear {
                MacWindowState.shared.setCursorHidden(false)
            }
            // Applied inside the environment injections so the modifier body can
            // read them, and outside `playbackControls` so shortcuts keep working
            // while the overlay is hidden.
            .modifier(VideoPlayer.KeyCommandsModifier())
            .environmentObject(containerState)
            .environmentObject(manager)
        }
    }

    final class UIVideoPlayerContainerViewController: NSObject {

        func presentSupplementContainer(
            _ didPresent: Bool,
            with panningState: (translation: CGFloat, velocity: CGFloat)? = nil,
            presentationStyle: MediaPlayerSupplementPresentationStyle? = nil
        ) {}
    }
}
#endif
