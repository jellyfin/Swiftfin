//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Engine
import SwiftUI

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

        private struct PlayerContainerView: View {

            @EnvironmentObject
            private var containerState: VideoPlayerContainerState

            let player: AnyView

            var body: some View {
                player
                    .overlay(Color.black.opacity(containerState.isPresentingPlaybackControls ? 0.3 : 0.0))
                    .animation(.linear(duration: 0.2), value: containerState.isPresentingPlaybackControls)
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
                content: OverlayToastView(proxy: containerState.toastProxy) {
                    ZStack {
                        GestureView()
                            .environment(\.panGestureDirection, .vertical)

                        playbackControls
                            .environment(\.onPressEventPublisher, onPressEvent)
                            .environmentObject(containerState)
                            .environmentObject(containerState.scrubbedSeconds)
                            .environmentObject(focusGuide)
                            .environmentObject(manager)
                    }
                    .environment(
                        \.panAction,
                        .init(
                            action: { [self] in
                                containerState.containerView?.handleSupplementPanAction(
                                    translation: $0,
                                    velocity: $1.y,
                                    location: $2,
                                    state: $4
                                )
                            }
                        )
                    )
                }
                .eraseToAnyView()
            )
            controller.disablesSafeArea = true
            controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            return controller
        }()

        private lazy var supplementContainerViewController: HostingController<AnyView> = {
            let content = ZStack {
                GestureView()
                    .environment(\.panGestureDirection, .vertical)

                SupplementContainerView()
                    .environmentObject(containerState)
                    .environmentObject(focusGuide)
                    .environmentObject(manager)
            }
            .environment(
                \.panAction,
                .init(
                    action: { [self] in
                        containerState.containerView?.handleSupplementPanAction(
                            translation: $0,
                            velocity: $1.y,
                            location: $2,
                            state: $4
                        )
                    }
                )
            )
            .eraseToAnyView()
            let controller = HostingController(content: content)
            controller.disablesSafeArea = true
            controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            return controller
        }()

        private var playerView: UIView { playerViewController.view }
        private var playbackControlsView: UIView { playbackControlsViewController.view }
        private var supplementContainerView: UIView { supplementContainerViewController.view }

        private var supplementRegularConstraints: [NSLayoutConstraint] = []
        private var playerRegularConstraints: [NSLayoutConstraint] = []
        private var playbackControlsConstraints: [NSLayoutConstraint] = []

        private var supplementHeightAnchor: NSLayoutConstraint!
        private var supplementBottomAnchor: NSLayoutConstraint!

        private let manager: MediaPlayerManager
        private let player: AnyView
        private let playbackControls: AnyView
        private let containerState: VideoPlayerContainerState

        let focusGuide = FocusGuide()
        let onPressEvent = OnPressEvent()

        private var cancellables: Set<AnyCancellable> = []

        // MARK: - Pan Gesture State

        private var lastVerticalPanLocation: CGPoint?
        private var verticalPanGestureStartConstant: CGFloat?
        private var isPanning: Bool = false
        private var didStartPanningWithSupplement: Bool = false

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

            let supplementContainerOffset: CGFloat = (view.bounds.height / 3) + EdgeInsets.edgePadding * 2
            let dismissedOffset: CGFloat = 50 + EdgeInsets.edgePadding * 2
            let minimumTranslation: CGFloat = 100.0

            if state == .began {
                self.view.layer.removeAllAnimations()
                didStartPanningWithSupplement = containerState.selectedSupplement != nil
                verticalPanGestureStartConstant = supplementBottomAnchor.constant
            }

            if state == .began || state == .changed {
                lastVerticalPanLocation = location
                isPanning = true

                let shouldHaveSupplementPresented = self.supplementBottomAnchor.constant < -(minimumTranslation + dismissedOffset)

                if shouldHaveSupplementPresented, !containerState.isPresentingSupplement {
                    containerState.selectedSupplement = manager.supplements.first
                } else if !shouldHaveSupplementPresented, containerState.selectedSupplement != nil {
                    containerState.selectedSupplement = nil
                }
            } else {
                lastVerticalPanLocation = nil
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
                max: -dismissedOffset
            )

            if newOffset < clampedOffset {
                let excess = clampedOffset - newOffset
                let resistance = pow(excess, 0.7)
                supplementBottomAnchor.constant = clampedOffset - resistance
            } else if newOffset > -dismissedOffset {
                let excess = newOffset - clampedOffset
                let resistance = pow(excess, 0.5)
                supplementBottomAnchor.constant = clamp(clampedOffset + resistance, min: -dismissedOffset, max: -50)
            } else {
                supplementBottomAnchor.constant = clampedOffset
            }

            containerState.supplementOffset = supplementBottomAnchor.constant
        }

        // MARK: - didPresent

        func presentSupplementContainer(
            _ didPresent: Bool,
            with panningState: (translation: CGFloat, velocity: CGFloat)? = nil
        ) {
            guard !isPanning else { return }

            if didPresent {
                self.supplementBottomAnchor.constant = -((view.bounds.height / 3) + EdgeInsets.edgePadding * 2)
            } else {
                self.supplementBottomAnchor.constant = -(50 + EdgeInsets.edgePadding * 2)
            }

            containerState.isPresentingPlaybackControls = !didPresent
            containerState.supplementOffset = supplementBottomAnchor.constant

            /// Force layout BEFORE animation
            view.setNeedsLayout()

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
                    withDuration: 0.75,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0.4,
                    options: .allowUserInteraction
                ) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            }
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .black

            setupViews()
            setupConstraints()

            let gesture = UITapGestureRecognizer(target: self, action: #selector(ignorePress))
            gesture.allowedPressTypes = [NSNumber(value: UIPress.PressType.menu.rawValue)]
            view.addGestureRecognizer(gesture)
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
        }

        private func setupConstraints() {
            playerRegularConstraints = [
                playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerView.topAnchor.constraint(equalTo: view.topAnchor),
                playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]

            NSLayoutConstraint.activate(playerRegularConstraints)

            supplementBottomAnchor = supplementContainerView.topAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -(50 + EdgeInsets.edgePadding * 2)
            )
            containerState.supplementOffset = supplementBottomAnchor.constant

            let constant = (view.bounds.height / 3) + EdgeInsets.edgePadding * 2
            supplementHeightAnchor = supplementContainerView.heightAnchor.constraint(equalToConstant: constant)

            supplementRegularConstraints = [
                supplementContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                supplementContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                supplementBottomAnchor,
                supplementHeightAnchor,
            ]

            NSLayoutConstraint.activate(supplementRegularConstraints)

            playbackControlsConstraints = [
                playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playbackControlsView.topAnchor.constraint(equalTo: view.topAnchor),
                playbackControlsView.bottomAnchor.constraint(equalTo: supplementContainerView.topAnchor),
            ]

            NSLayoutConstraint.activate(playbackControlsConstraints)
        }

        deinit {
            /// Clean up constraints
            NSLayoutConstraint.deactivate(playerRegularConstraints)
            NSLayoutConstraint.deactivate(supplementRegularConstraints)
            NSLayoutConstraint.deactivate(playbackControlsConstraints)

            /// Clean up gesture state
            lastVerticalPanLocation = nil
            verticalPanGestureStartConstant = nil

            /// Clean up child view controllers
            playerViewController.willMove(toParent: nil)
            playerViewController.removeFromParent()

            playbackControlsViewController.willMove(toParent: nil)
            playbackControlsViewController.removeFromParent()

            supplementContainerViewController.willMove(toParent: nil)
            supplementContainerViewController.removeFromParent()

            /// Clean up views
            playerView.removeFromSuperview()
            playbackControlsView.removeFromSuperview()
            supplementContainerView.removeFromSuperview()
        }

        @objc
        func ignorePress() {}

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

        override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
            for press in presses {
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
}

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
