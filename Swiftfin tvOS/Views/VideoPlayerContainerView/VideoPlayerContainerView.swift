//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import MediaPlayer
import SwiftUI

// TODO: use video size from proxies to control aspect fill
//       - stay within safe areas, aspect fill to screen
// TODO: instead of static sizes for supplement view, take into account available space
//       - necessary for full-screen supplements and/or small screens
// TODO: custom buttons on playback controls
//       - skip intro, next episode, etc.
//       - can just do on playback controls itself
// TODO: no supplements state
//       - don't pan
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
            UIVideoPlayerContainerViewController(
                containerState: containerState,
                manager: manager,
                player: player().eraseToAnyView(),
                playbackControls: playbackControls().eraseToAnyView()
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

            @EnvironmentObject
            private var manager: MediaPlayerManager

            var body: some View {
                player
                    .overlay(Color.black.opacity(containerState.isPresentingPlaybackControls ? 0.3 : 0.0))
                    .overlay {
                        if manager.playbackRequestStatus == .paused {
                            Label(L10n.pause, systemImage: "pause.fill")
                                .transition(.opacity.combined(with: .scale).animation(.bouncy(duration: 0.7, extraBounce: 0.2)))
                                .font(.system(size: 72, weight: .bold, design: .default))
                                .labelStyle(.iconOnly)
                        }
                    }
                    .animation(.linear(duration: 0.2), value: containerState.isPresentingPlaybackControls)
            }
        }

        private struct PlaybackControlsContainerView: View {

            @EnvironmentObject
            private var containerState: VideoPlayerContainerState

            let playbackControls: AnyView
            let onPressEvent: OnPressEvent

            var body: some View {
                OverlayToastView(proxy: containerState.toastProxy) {
                    playbackControls
                        .environment(\.onPressEventPublisher, onPressEvent)
                        .environmentObject(containerState.scrubbedSeconds)
                }
            }
        }

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
                content: PlaybackControlsContainerView(
                    playbackControls: playbackControls,
                    onPressEvent: onPressEvent
                )
                .environmentObject(containerState)
                .environmentObject(focusGuide)
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
                .environmentObject(focusGuide)
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

        private var supplementContainerOffset: CGFloat {
            (view.bounds.height / 3) + EdgeInsets.edgePadding * 2
        }

        private let minimumTranslation: CGFloat = 100.0

        // MARK: - Constraints

        private var supplementHeightAnchor: NSLayoutConstraint!
        private var supplementBottomAnchor: NSLayoutConstraint!

        // MARK: - Properties

        private let manager: MediaPlayerManager
        private let player: AnyView
        private let playbackControls: AnyView
        private let containerState: VideoPlayerContainerState
        private let focusGuide = FocusGuide()

        let onPressEvent = OnPressEvent()

        // MARK: - Pan Gesture State

        private var verticalPanGestureStartConstant: CGFloat?
        private var isPanning: Bool = false
        private var didStartPanningWithSupplement: Bool = false
        private var lastTouchPokeTime: CFTimeInterval = 0

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

        // MARK: - Supplement Pan Action

        func handleSupplementPanAction(
            translation: CGPoint,
            velocity: CGFloat,
            location: CGPoint,
            state: UIGestureRecognizer.State
        ) {
            let yDirection: CGFloat = translation.y > 0 ? -1 : 1
            let newOffset: CGFloat
            let clampedOffset: CGFloat

            if state == .began {
                self.view.layer.removeAllAnimations()
                didStartPanningWithSupplement = containerState.selectedSupplement != nil
                verticalPanGestureStartConstant = supplementBottomAnchor.constant
            }

            if state == .began || state == .changed {
                isPanning = true

                let shouldHaveSupplementPresented = self.supplementBottomAnchor
                    .constant < -(minimumTranslation + EdgeInsets.edgePadding)

                if shouldHaveSupplementPresented, !containerState.isPresentingSupplement {
                    containerState.selectedSupplement = manager.supplements.first
                } else if !shouldHaveSupplementPresented, containerState.selectedSupplement != nil {
                    containerState.selectedSupplement = nil
                }
            } else {
                verticalPanGestureStartConstant = nil
                isPanning = false

                let shouldActuallyDismissSupplement = didStartPanningWithSupplement &&
                    (translation.y > minimumTranslation || velocity > 1000)
                if shouldActuallyDismissSupplement {
                    containerState.selectedSupplement = nil
                }

                let shouldActuallyPresentSupplement = !didStartPanningWithSupplement &&
                    (translation.y < -minimumTranslation || velocity < -1000)
                if shouldActuallyPresentSupplement {
                    containerState.selectedSupplement = manager.supplements.first
                }

                let stateToPass: (translation: CGFloat, velocity: CGFloat)? = (translation: translation.y, velocity: velocity)
                presentSupplementContainer(containerState.selectedSupplement != nil, with: stateToPass)
                return
            }

            guard let verticalPanGestureStartConstant else { return }

            if (!didStartPanningWithSupplement && yDirection > 0) || (didStartPanningWithSupplement && yDirection < 0) {
                newOffset = verticalPanGestureStartConstant + (translation.y.magnitude * -yDirection)
            } else {
                newOffset = verticalPanGestureStartConstant - (translation.y.magnitude * yDirection)
            }

            clampedOffset = clamp(
                newOffset,
                min: -supplementContainerOffset,
                max: -EdgeInsets.edgePadding
            )

            if newOffset < clampedOffset {
                let excess = clampedOffset - newOffset
                let resistance = pow(excess, 0.7)
                supplementBottomAnchor.constant = clampedOffset - resistance
            } else if newOffset > -EdgeInsets.edgePadding {
                let excess = newOffset - clampedOffset
                let resistance = pow(excess, 0.5)
                supplementBottomAnchor.constant = clamp(clampedOffset + resistance, min: -EdgeInsets.edgePadding, max: -50)
            } else {
                supplementBottomAnchor.constant = clampedOffset
            }

            containerState.supplementOffset = supplementBottomAnchor.constant
        }

        // MARK: - present

        func presentSupplementContainer(
            _ didPresent: Bool,
            redirectFocus: Bool = true,
            with panningState: (translation: CGFloat, velocity: CGFloat)? = nil
        ) {
            guard !isPanning else { return }

            if didPresent {
                self.supplementBottomAnchor.constant = -supplementContainerOffset
                containerState.isPresentingOverlay = true
                supplementContainerView.isUserInteractionEnabled = true
            } else {
                self.supplementBottomAnchor.constant = -EdgeInsets.edgePadding
                supplementContainerView.isUserInteractionEnabled = false
            }

            containerState.isPresentingPlaybackControls = true
            containerState.supplementOffset = supplementBottomAnchor.constant

            view.setNeedsLayout()

            if redirectFocus && !didPresent {
                focusGuide.transition(to: nil)
                DispatchQueue.main.async { [self] in
                    focusGuide.transition(to: "progressBar")
                }
            }

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
                    withDuration: 0.55,
                    delay: 0,
                    usingSpringWithDamping: 0.85,
                    initialSpringVelocity: 0.3,
                    options: .allowUserInteraction
                ) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            }
        }

        // MARK: - viewDidLoad

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .black

            setupViews()
            setupConstraints()

            let gesture = UITapGestureRecognizer(target: self, action: #selector(menuPressed))
            gesture.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
            view.addGestureRecognizer(gesture)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            Task { @MainActor in
                disableTogglePlayPauseCommand()
            }
        }

        private func disableTogglePlayPauseCommand() {
            let cmd = MPRemoteCommandCenter.shared().togglePlayPauseCommand
            cmd.removeTarget(nil)
            cmd.addTarget { _ in .success }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            guard manager.state != .stopped else { return }

            Task { @MainActor in
                manager.stop()
            }
        }

        private func setupViews() {
            addChild(playerViewController)
            view.addSubview(playerView)
            playerViewController.didMove(toParent: self)
            playerView.backgroundColor = .black

            addChild(playbackControlsViewController)
            view.addSubview(playbackControlsView)
            playbackControlsViewController.didMove(toParent: self)
            playbackControlsView.backgroundColor = .clear

            addChild(supplementContainerViewController)
            view.addSubview(supplementContainerView)
            supplementContainerViewController.didMove(toParent: self)
            supplementContainerView.backgroundColor = .clear

            supplementContainerView.isUserInteractionEnabled = false
        }

        private func setupConstraints() {
            let playerConstraints = [
                playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerView.topAnchor.constraint(equalTo: view.topAnchor),
                playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]

            NSLayoutConstraint.activate(playerConstraints)

            supplementBottomAnchor = supplementContainerView.topAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -EdgeInsets.edgePadding
            )
            containerState.supplementOffset = supplementBottomAnchor.constant

            supplementHeightAnchor = supplementContainerView.heightAnchor.constraint(equalToConstant: supplementContainerOffset)

            let supplementConstraints = [
                supplementContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                supplementContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                supplementBottomAnchor!,
                supplementHeightAnchor!,
            ]

            NSLayoutConstraint.activate(supplementConstraints)

            let playbackControlsConstraints = [
                playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playbackControlsView.topAnchor.constraint(equalTo: view.topAnchor),
                playbackControlsView.bottomAnchor.constraint(equalTo: supplementContainerView.topAnchor),
            ]

            NSLayoutConstraint.activate(playbackControlsConstraints)
        }

        // MARK: - Touch Handling

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

        // MARK: - Press Handling

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

        // MARK: - Play/Pause

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

        // MARK: - Select

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

        // MARK: - Menu

        private func handleMenuEnded() {
            if !containerState.isPresentingOverlay {
                containerState.isPresentingOverlay = true
                containerState.timer.poke()
                return
            }

            if containerState.hasEnteredScrubMode {
                containerState.cancelScrub()
                containerState.timer.poke()
            } else if containerState.isPresentingSupplement {
                containerState.selectedSupplement = nil
                presentSupplementContainer(false, redirectFocus: false)
                containerState.timer.poke()
                focusGuide.transition(to: nil)
                DispatchQueue.main.async { [self] in
                    focusGuide.transition(to: "progressBar")
                }
            } else {
                containerState.isPresentingCloseConfirmation = true
            }
        }
    }
}

// MARK: - PressEvent

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

// MARK: - OnPressEvent Property Wrapper

@propertyWrapper
struct OnPressEvent: DynamicProperty {

    @Environment(\.onPressEventPublisher)
    private var publisher

    var wrappedValue: VideoPlayer.UIVideoPlayerContainerViewController.OnPressEvent {
        publisher
    }
}

extension EnvironmentValues {

    @Entry
    var onPressEventPublisher: VideoPlayer.UIVideoPlayerContainerViewController.OnPressEvent = .init()
}
