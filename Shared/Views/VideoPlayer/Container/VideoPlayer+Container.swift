//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Logging
import MediaPlayer
import SwiftUI

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

extension VideoPlayer {

    struct Container<Player: View, PlaybackControls: View>: PlatformViewControllerRepresentable {

        private let viewState: ViewState
        private let manager: MediaPlayerManager
        private let videoSize: PublishedBox<CGSize>
        private let player: (VideoLayout) -> Player
        private let playbackControls: PlaybackControls

        init(
            viewState: ViewState,
            manager: MediaPlayerManager,
            videoSize: PublishedBox<CGSize>,
            @ViewBuilder player: @escaping (VideoLayout) -> Player,
            @ViewBuilder playbackControls: @escaping () -> PlaybackControls
        ) {
            self.viewState = viewState
            self.manager = manager
            self.videoSize = videoSize
            self.player = player
            self.playbackControls = playbackControls()
        }

        func makeUIViewController(context: Context) -> UIContainerViewController {
            let audioOffset = context.environment.audioOffset
            let playerView = { (videoLayout: VideoLayout) in
                player(videoLayout)
                    .environment(\.audioOffset, audioOffset)
                    .eraseToAnyView()
            }

            let playbackControlsView = playbackControls
                .environment(\.audioOffset, audioOffset)
                .eraseToAnyView()

            return UIContainerViewController(
                viewState: viewState,
                manager: manager,
                videoSize: videoSize,
                player: playerView,
                playbackControls: playbackControlsView
            )
        }

        func updateUIViewController(
            _ uiViewController: UIContainerViewController,
            context: Context
        ) {}
    }

    // MARK: - UIContainerViewController

    class UIContainerViewController: UIViewController {

        typealias ViewState = VideoPlayer.ViewState

        // MARK: - Views

        // TODO: preview image while scrubbing option
        private struct PlayerContainerView: View {

            @Default(.VideoPlayer.aspectFillWithinSafeArea)
            private var aspectFillWithinSafeArea

            @Environment(ViewState.self)
            private var viewState

            let player: (VideoLayout) -> AnyView
            let videoSize: PublishedBox<CGSize>

            private var shouldPresentDimOverlay: Bool {
                viewState.visibleElements.contains(.dimming)
            }

            var body: some View {
                VideoViewport(
                    videoSize: videoSize,
                    fillWithinSafeArea: aspectFillWithinSafeArea,
                    hasNotch: UIDevice.hasNotch
                ) { videoLayout in
                    player(videoLayout)
                        #if os(iOS)
                            .overlay(Color.black.opacity(shouldPresentDimOverlay ? 0.5 : 0.0))
                        #endif
                        .overlay {
                            Group {
                                if viewState.selectedSupplement?.presentationStyle == .expanded {
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
        }

        private struct PlaybackControlsContainerView: View {

            @Environment(ViewState.self)
            private var viewState

            let playbackControls: AnyView

            var body: some View {
                OverlayToastView(proxy: viewState.toastProxy) {
                    Group {
                        #if os(iOS)
                        ZStack {
                            GestureView()
                                .environment(
                                    \.panGestureDirection,
                                    viewState.isPresentingSupplement
                                        ? .vertical
                                        : (viewState.isPresentingControls ? .up : .allButDown)
                                )

                            playbackControls
                        }
                        #else
                        playbackControls
                        #endif
                    }
                    .environmentObject(viewState.scrubbedSeconds)
                    .environmentObject(viewState.centerOffsetBox)
                }
                #if os(iOS)
                .environment(
                        \.longPressAction,
                        .init(
                            action: {
                                viewState.containerView?.handleLongPressGesture(
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
                                viewState.containerView?.handlePanGesture(
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
                                viewState.containerView?.handlePinchGesture(scale: $0, velocity: $1, state: $2)
                            }
                        )
                    )
                    .environment(
                        \.tapGestureAction,
                        .init(
                            action: {
                                viewState.containerView?.handleTapGesture(
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
                content: PlayerContainerView(player: player, videoSize: videoSize)
                    .environment(viewState)
                    .environmentObject(viewState.focusCoordinator)
                    .environmentObject(manager)
                    .eraseToAnyView()
            )
            controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            return controller
        }()

        private lazy var playbackControlsViewController: HostingController<AnyView> = {
            let controller = HostingController(
                content: PlaybackControlsContainerView(playbackControls: playbackControls)
                    .environment(viewState)
                    .environmentObject(viewState.focusCoordinator)
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
                .environment(viewState)
                .environmentObject(viewState.focusCoordinator)
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
            let isCompact = isCompact ?? viewState.isCompact
            let regularOffset = isCompact
                ? compactSupplementContainerOffset(totalHeight)
                : regularSupplementContainerOffset(totalHeight)

            guard !isCompact,
                  viewState.selectedSupplement?.presentationStyle == .expanded
            else {
                return regularOffset
            }

            return totalHeight
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
            guard viewState.isCompact,
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
            guard viewState.isCompact,
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
        private let videoSize: PublishedBox<CGSize>
        private let player: (VideoLayout) -> AnyView
        private let playbackControls: AnyView
        let viewState: ViewState

        private var didInitiallyAppear: Bool = false

        #if os(tvOS)
        let onPressEvent = OnPressEvent()
        private var lastTouchPokeTime: CFTimeInterval = 0
        #endif

        init(
            viewState: ViewState,
            manager: MediaPlayerManager,
            videoSize: PublishedBox<CGSize>,
            player: @escaping (VideoLayout) -> AnyView,
            playbackControls: AnyView
        ) {
            self.viewState = viewState
            self.manager = manager
            self.videoSize = videoSize
            self.player = player
            self.playbackControls = playbackControls

            super.init(nibName: nil, bundle: nil)

            viewState.containerView = self
            viewState.connect(manager: manager)
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

            // The pan owns layout until the final selection is committed below.
            isPanning = true

            if state == .began {
                self.view.layer.removeAllAnimations()
                didStartPanningWithSupplement = viewState.isPresentingSupplement
                verticalPanGestureStartConstant = supplementBottomAnchor.constant
                didStartPanningUpWithoutOverlay = !viewState.isPresentingControls
                if didStartPanningUpWithoutOverlay {
                    viewState.showControls()
                }
            }

            if state == .began || state == .changed {
                lastVerticalPanLocation = location

                let minimumTranslation =
                    -((viewState.isCompact ? compactMinimumTranslation : regularMinimumTranslation) +
                        dismissedSupplementContainerOffset
                    )
                let shouldHaveSupplementPresented = supplementBottomAnchor.constant < minimumTranslation

                if shouldHaveSupplementPresented, !viewState.isPresentingSupplement {
                    viewState.selectedSupplementID = manager.supplements.first?.id
                } else if !shouldHaveSupplementPresented, viewState.isPresentingSupplement {
                    viewState.selectedSupplementID = nil
                }
            } else {
                lastVerticalPanLocation = nil
                verticalPanGestureStartConstant = nil

                let translationMin: CGFloat = viewState.isCompact ? compactMinimumTranslation : regularMinimumTranslation
                let shouldActuallyDismissSupplement = didStartPanningWithSupplement && (translation.y > translationMin || velocity > 1000)
                if shouldActuallyDismissSupplement {
                    // If we started with a supplement and panned down more than 100 points, dismiss it
                    viewState.selectedSupplementID = nil
                }

                let shouldActuallyPresentSupplement = !didStartPanningWithSupplement &&
                    (translation.y < -translationMin || velocity < -1000)
                if shouldActuallyPresentSupplement {
                    // If we didn't start with a supplement and panned up more than 100 points, present it
                    viewState.selectedSupplementID = manager.supplements.first?.id
                }

                let stateToPass: (translation: CGFloat, velocity: CGFloat)? = lastVerticalPanLocation != nil &&
                    verticalPanGestureStartConstant !=
                    nil ?
                    (translation: translation.y, velocity: velocity) : nil
                isPanning = false
                presentSupplementContainer(viewState.isPresentingSupplement, with: stateToPass)

                let shouldActuallyDismissOverlay = didStartPanningUpWithoutOverlay && !viewState.isPresentingSupplement

                if shouldActuallyDismissOverlay {
                    viewState.hideControls()
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
            viewState.centerOffsetBox.value = centerOffset
        }

        // MARK: - present

        func presentSupplementContainer(
            _ didPresent: Bool,
            with panningState: (translation: CGFloat, velocity: CGFloat)? = nil
        ) {
            guard !isPanning else { return }
            guard let supplementBottomAnchor,
                  let supplementHeightAnchor,
                  let playerCompactBottomAnchor
            else { return }

            if didPresent {
                let presentedOffset = supplementContainerOffset(for: view.bounds.height)
                supplementHeightAnchor.constant = presentedOffset
                supplementBottomAnchor.constant = -presentedOffset
            } else {
                supplementBottomAnchor.constant = -dismissedSupplementContainerOffset
            }

            playerCompactBottomAnchor.constant = compactPlayerBottomOffset
            viewState.centerOffsetBox.value = centerOffset

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
                    withDuration: viewState.isCompact ? 0.75 : 0.6,
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
                viewState.showControls()
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
                viewState.isCompact = isCompact
                viewState.centerOffsetBox.value = centerOffset
            }

            #if os(tvOS)
            let gesture = UITapGestureRecognizer(target: self, action: #selector(handleMenuEnded))
            gesture.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
            view.addGestureRecognizer(gesture)
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

            if viewState.isCompact {
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
            viewState.isCompact = isCompact

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

            supplementBottomAnchor.constant = viewState
                .isPresentingSupplement ? -presentedOffset : -dismissedSupplementContainerOffset
            supplementHeightAnchor.constant = presentedOffset

            playerCompactBottomAnchor.constant = compactPlayerBottomOffset
            viewState.centerOffsetBox.value = centerOffset
        }

        // MARK: - tvOS

        #if os(tvOS)
        override func updateProperties() {
            super.updateProperties()
            supplementContainerView.isUserInteractionEnabled = viewState.visibleElements.contains(.supplements)
        }

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

            if manager.item.isLiveStream {
                viewState.showControls()
            } else {
                viewState.showProgress()
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

        override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            for press in presses {
                onPressEvent.send(
                    .init(type: press.type, phase: .cancelled) { [weak self] in
                        self?.forwardPressesCancelled([press], event: event)
                    }
                )
            }
        }

        private func forwardPressesCancelled(_ presses: Set<UIPress>, event: UIPressesEvent?) {
            super.pressesCancelled(presses, with: event)
        }

        private func handlePlayPauseEnded() {
            if viewState.isScrubbing {
                viewState.cancelScrub()
                return
            }

            if viewState.presentation == .hidden {
                if manager.playbackRequestStatus == .paused {
                    manager.setPlaybackRequestStatus(status: .playing)
                }
                viewState.showControls()
            } else {
                switch manager.playbackRequestStatus {
                case .playing:
                    manager.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    manager.setPlaybackRequestStatus(status: .playing)
                }
            }

            viewState.refreshAutoDismiss()
        }

        private func handleSelectEnded(_ press: UIPress, event: UIPressesEvent?) {
            if viewState.presentation == .hidden {
                viewState.showControls()
                return
            }

            if viewState.isScrubbing {
                viewState.commitScrub()
            } else if viewState.isProgressBarFocused {
                switch manager.playbackRequestStatus {
                case .playing:
                    manager.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    manager.setPlaybackRequestStatus(status: .playing)
                }
                viewState.refreshAutoDismiss()
            } else {
                forwardPressesEnded([press], event: event)
            }
        }

        @objc
        private func handleMenuEnded() {
            // Let a system menu or alert consume Back before dismissing player UI.
            guard !viewState.isFocusOutsidePlayer || viewState.presentation == .hidden else { return }

            if viewState.isScrubbing {
                viewState.cancelScrub()
            } else if viewState.isPresentingSupplement {
                viewState.selectedSupplementID = nil
            } else if viewState.presentation != .hidden {
                viewState.hideControls()
            } else if Defaults[.confirmClose] {
                viewState.isPresentingCloseConfirmation = true
            } else {
                manager.stop()
            }
        }
        #endif
    }
}

// MARK: - tvOS PressEvent

#if os(tvOS)
extension VideoPlayer.UIContainerViewController {

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
