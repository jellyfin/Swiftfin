//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Engine
import SwiftUI

// TODO: don't dismiss overlay while panning and supplement not presented
// TODO: use video size from proxies to control aspect fill
//       - stay within safe areas, aspect fill to screen
// TODO: instead of static sizes for supplement view, take into account available space
//       - necessary for full-screen supplements and/or small screens
// TODO: custom buttons on playback controls
//       - skip intro, next episode, etc.
// TODO: pass in safe area insets explicitly?

// MARK: - VideoPlayerContainerView

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
            .environment(\.isGestureLocked, context.environment.isGestureLocked)
            .eraseToAnyView()
        let playbackControlsView = playbackControls()
            .environment(\.audioOffset, context.environment.audioOffset)
            .environment(\.isGestureLocked, context.environment.isGestureLocked)
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
    ) {
        context.environment.presentationControllerShouldDismiss.wrappedValue = containerState.presentationControllerShouldDismiss
    }
}

// MARK: - UIVideoPlayerContainerViewController

class UIVideoPlayerContainerViewController: UIViewController {

    // MARK: - Views

    // TODO: preview image while scrubbing
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
        }
    }

    private struct PlaybackControlsContainerView: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        let playbackControls: AnyView

        var body: some View {
            ToastView {
                ZStack {
                    GestureView()
                        .environment(\.panGestureDirection, containerState.presentationControllerShouldDismiss ? .up : .vertical)

                    playbackControls
                }
                // inject box explicitly
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
            content: PlaybackControlsContainerView(playbackControls: playbackControls)
                .environment(
                    \.panGestureAction,
                    .init(
                        action: {
                            [weak self] in self?.handlePanGesture(
                                translation: $0,
                                velocity: $1,
                                location: $2,
                                state: $3
                            )
                        }
                    )
                )
                .environment(
                    \.pinchGestureAction,
                    .init(action: { [weak self] in self?.handlePinchGesture(scale: $0, velocity: $1, state: $2) })
                )
                .environment(
                    \.tapGestureAction,
                    .init(action: { [weak self] in self?.handleTapGesture(location: $0, count: $1) })
                )
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
            .environment(
                \.panGestureAction,
                .init(
                    action: {
                        [weak self] in self?.handlePanGesture(
                            translation: $0,
                            velocity: $1,
                            location: $2,
                            state: $3
                        )
                    }
                )
            )
            .environment(
                \.tapGestureAction,
                .init(
                    action: { [weak self] in self?.handleTapGesture(location: $0, count: $1) }
                )
            )
            .environmentObject(containerState)
            .environmentObject(manager)
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

    // MARK: - Constants

    private let compactSupplementContainerOffset: (CGFloat) -> CGFloat = { totalHeight in
        max(totalHeight * 0.6, 300) + EdgeInsets.edgePadding * 2
    }

    private let regularSupplementContainerOffset: CGFloat = 200.0 + EdgeInsets.edgePadding * 2
    private let dismissedSupplementContainerOffset: CGFloat = 50.0 + EdgeInsets.edgePadding * 2

    private let compactMinimumTranslation: CGFloat = 100.0
    private let regularMinimumTranslation: CGFloat = 50.0

    // MARK: - Constraints

    private var playbackControlsConstraints: [NSLayoutConstraint] = []
    private var playerCompactConstraints: [NSLayoutConstraint] = []
    private var playerRegularConstraints: [NSLayoutConstraint] = []
    private var supplementContainerConstraints: [NSLayoutConstraint] = []

    private var playerCompactBottomAnchor: NSLayoutConstraint!
    private var supplementHeightAnchor: NSLayoutConstraint!
    private var supplementBottomAnchor: NSLayoutConstraint!

    private var centerOffset: CGFloat {
        guard containerState.isCompact else {
            return dismissedSupplementContainerOffset
        }

        let supplementContainerHeight = compactSupplementContainerOffset(view.bounds.height)
        let offsetPercentage = 1 - clamp(abs(supplementBottomAnchor.constant) / supplementContainerHeight, min: 0, max: 1)
        let offset = (dismissedSupplementContainerOffset + EdgeInsets.edgePadding) * offsetPercentage

        return max(50, offset)
    }

    private var compactPlayerBottomOffset: CGFloat {
        guard containerState.isCompact else {
            return dismissedSupplementContainerOffset
        }
        let supplementContainerHeight = compactSupplementContainerOffset(view.bounds.height)
        let offsetPercentage = 1 - clamp(abs(supplementBottomAnchor.constant) / supplementContainerHeight, min: 0, max: 1)
        let offset = (dismissedSupplementContainerOffset + EdgeInsets.edgePadding) * offsetPercentage

        return offset
    }

    private let manager: MediaPlayerManager
    private let player: AnyView
    private let playbackControls: AnyView
    let containerState: VideoPlayerContainerState

    private var cancellables: Set<AnyCancellable> = []

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
                -((containerState.isCompact ? compactMinimumTranslation : regularMinimumTranslation) + dismissedSupplementContainerOffset)
            let shouldHaveSupplementPresented = self.supplementBottomAnchor.constant < minimumTranslation

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

            let shouldActuallyPresentSupplement = !didStartPanningWithSupplement && (translation.y < -translationMin || velocity < -1000)
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

        if (!didStartPanningWithSupplement && yDirection > 0) || (didStartPanningWithSupplement && yDirection < 0) {
            // If we started with a supplement and are panning down, or if we didn't start with a supplement and are panning up
            newOffset = verticalPanGestureStartConstant! + (abs(translation.y) * -yDirection)
        } else {
            newOffset = verticalPanGestureStartConstant! - (abs(translation.y) * yDirection)
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
        containerState.supplementOffset = supplementBottomAnchor.constant
        containerState.centerOffset = centerOffset
    }

    // MARK: - present

    func presentSupplementContainer(
        _ didPresent: Bool,
        with panningState: (translation: CGFloat, velocity: CGFloat)? = nil
    ) {
        guard !isPanning else { return }

        if didPresent {
            if containerState.isCompact {
                self.supplementBottomAnchor.constant = -compactSupplementContainerOffset(view.bounds.size.height)
            } else {
                self.supplementBottomAnchor.constant = -regularSupplementContainerOffset
            }
        } else {
            self.supplementBottomAnchor.constant = -dismissedSupplementContainerOffset
        }

        playerCompactBottomAnchor.constant = compactPlayerBottomOffset
        containerState.supplementOffset = supplementBottomAnchor.constant
        containerState.centerOffset = centerOffset

        if let panningState {
            let velocity = abs(panningState.velocity) / 1000
            let distance = abs(panningState.translation)
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

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        containerState.isCompact = UIDevice.isPhone && view.bounds.size.isPortrait

        setupViews()
        setupConstraints()
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

        let isCompact = UIDevice.isPhone && view.bounds.size.isPortrait

        supplementBottomAnchor = supplementContainerView.topAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -dismissedSupplementContainerOffset
        )
        containerState.supplementOffset = supplementBottomAnchor.constant
        containerState.centerOffset = centerOffset

        let constant = isCompact ?
            compactSupplementContainerOffset(view.bounds.height) :
            regularSupplementContainerOffset
        supplementHeightAnchor = supplementContainerView.heightAnchor.constraint(equalToConstant: constant)

        supplementContainerConstraints = [
            supplementContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            supplementContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            supplementBottomAnchor,
            supplementHeightAnchor,
        ]

        NSLayoutConstraint.activate(supplementContainerConstraints)

        playbackControlsConstraints = [
            playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playbackControlsView.topAnchor.constraint(equalTo: view.topAnchor),
            playbackControlsView.bottomAnchor.constraint(equalTo: supplementContainerView.topAnchor),
        ]

        NSLayoutConstraint.activate(playbackControlsConstraints)

        playerCompactBottomAnchor = playerView.bottomAnchor.constraint(
            equalTo: supplementContainerView.topAnchor,
            constant: compactPlayerBottomOffset
        )

        playerCompactConstraints = [
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerCompactBottomAnchor,
        ]
        playerRegularConstraints = [
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]

        if isCompact {
            NSLayoutConstraint.activate(playerCompactConstraints)
        } else {
            NSLayoutConstraint.activate(playerRegularConstraints)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        adjustContraints(isCompact: UIDevice.isPhone && size.isPortrait, in: size)
    }

    private func adjustContraints(isCompact: Bool, in newSize: CGSize) {
        containerState.isCompact = isCompact

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
        containerState.supplementOffset = supplementHeightAnchor.constant
        containerState.centerOffset = centerOffset
    }
}
