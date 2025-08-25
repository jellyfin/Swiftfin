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

struct VideoPlayerContainerView<Player: View, PlaybackControls: View>: UIViewControllerRepresentable {

    @EnvironmentObject
    private var manager: MediaPlayerManager

    private let player: () -> Player
    private let playbackControls: () -> PlaybackControls

    init(
        @ViewBuilder player: @escaping () -> Player,
        @ViewBuilder playbackControls: @escaping () -> PlaybackControls
    ) {
        self.player = player
        self.playbackControls = playbackControls
    }

    func makeUIViewController(context: Context) -> UIVideoPlayerContainerViewController {
        UIVideoPlayerContainerViewController(
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

    private struct PlaybackControlsContainerView: View {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        let playbackControls: AnyView

        var body: some View {
            ZStack {
                GestureView()

                playbackControls
            }
        }
    }

    private lazy var playerViewController: HostingController<AnyView> = {
        let controller = HostingController(
            content: PlayerContainerView(player: player)
                .environmentObject(containerState)
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
                .environment(\.panGestureAction, .init(action: handlePanGesture))
                .environment(\.tapGestureAction, .init(action: handleTapGesture))
                .eraseToAnyView()
        )
        controller.disablesSafeArea = true
        controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        return controller
    }()

    private lazy var supplementContainerViewController: HostingController<AnyView> = {
        let content = SupplementContainerView()
            .environmentObject(self.manager)
            .environmentObject(self.containerState)
            .environment(\.panGestureAction, .init(action: handlePanGesture))
            .environment(\.tapGestureAction, .init(action: handleTapGesture))
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
        max(totalHeight * 0.6 + EdgeInsets.edgePadding * 2, 300 + EdgeInsets.edgePadding * 2)
    }

    private let regularSupplementContainerOffset: CGFloat = 200.0 + EdgeInsets.edgePadding * 2
    private let dismissedSupplementContainerOffset: CGFloat = 50.0 + EdgeInsets.edgePadding

    private let compactMinimumTranslation: CGFloat = 100.0
    private let regularMinimumTranslation: CGFloat = 50.0

    // MARK: - Constraints

    private var playbackControlsConstraints: [NSLayoutConstraint] = []
    private var playerCompactConstraints: [NSLayoutConstraint] = []
    private var playerRegularConstraints: [NSLayoutConstraint] = []
    private var supplementContainerConstraints: [NSLayoutConstraint] = []

    private var supplementHeightAnchor: NSLayoutConstraint!
    private var supplementBottomAnchor: NSLayoutConstraint!

    private let manager: MediaPlayerManager
    private let player: AnyView
    private let playbackControls: AnyView
    private let containerState: VideoPlayerContainerState

    private var isCompact: Bool = false {
        didSet {
            guard containerState.isPresentingSupplement else { return }
            containerState.isPresentingPlaybackControls = isCompact
        }
    }

    private var cancellables: Set<AnyCancellable> = []

    init(
        manager: MediaPlayerManager,
        player: AnyView,
        playbackControls: AnyView
    ) {
        self.containerState = VideoPlayerContainerState()
        self.manager = manager
        self.player = player
        self.playbackControls = playbackControls

        super.init(nibName: nil, bundle: nil)

        self.containerState.$selectedSupplement
            .dropFirst()
            .sink { newSupplement in
                print("Selected Supplement: \(String(describing: newSupplement))")
                self.didPresent(supplement: newSupplement)
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var lastVerticalPanLocation: CGPoint?
    private var verticalPanGestureStartConstant: CGFloat?
    private var isPanning: Bool = false
    private var didStartPanningWithSupplement: Bool = false
    private var didStartPanningUpWithoutOverlay: Bool = false

    // MARK: - Pan

    private func handlePanGesture(
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
                -((isCompact ? compactMinimumTranslation : regularMinimumTranslation) + dismissedSupplementContainerOffset)
            let shouldHaveSupplementPresented = self.supplementBottomAnchor.constant < minimumTranslation

            if shouldHaveSupplementPresented, !containerState.isPresentingSupplement {
                containerState.selectedSupplement = manager.supplements.first?.asAny
            } else if !shouldHaveSupplementPresented {
                containerState.selectedSupplement = nil
            }
        } else {
            lastVerticalPanLocation = nil
            verticalPanGestureStartConstant = nil
            isPanning = false

            let translationMin: CGFloat = isCompact ? compactMinimumTranslation : regularMinimumTranslation
            let shouldActuallyDismissSupplement = didStartPanningWithSupplement && (translation.y > translationMin || velocity > 1000)
            if shouldActuallyDismissSupplement {
                // If we started with a supplement and panned down more than 100 points, dismiss it
                containerState.selectedSupplement = nil
                containerState.isPresentingPlaybackControls = true
            }

            let shouldActuallyPresentSupplement = !didStartPanningWithSupplement && (translation.y < -translationMin || velocity < -1000)
            if shouldActuallyPresentSupplement {
                // If we didn't start with a supplement and panned up more than 100 points, present it
                containerState.selectedSupplement = manager.supplements.first?.asAny
            }

            let stateToPass: (translation: CGFloat, velocity: CGFloat)? = lastVerticalPanLocation != nil &&
                verticalPanGestureStartConstant !=
                nil ?
                (translation: translation.y, velocity: velocity) : nil
            didPresent(supplement: containerState.selectedSupplement, with: stateToPass)

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

        if isCompact {
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

        containerState.supplementOffset = supplementBottomAnchor.constant
    }

    // MARK: - Tap

    private func handleTapGesture(
        location: UnitPoint,
        count: Int
    ) {
        if count == 1 {
            if containerState.isPresentingSupplement {
                if isCompact {
                    containerState.isPresentingPlaybackControls.toggle()
                } else {
                    containerState.selectedSupplement = nil
                }
            } else {
                containerState.isPresentingOverlay.toggle()
            }
        }
    }

    // MARK: - didPresent

    func didPresent(
        supplement: AnyMediaPlayerSupplement?,
        with panningState: (translation: CGFloat, velocity: CGFloat)? = nil
    ) {
        guard !isPanning else { return }

        let didPresent = supplement != nil

        if didPresent {
            if isCompact {
                self.supplementBottomAnchor.constant = -compactSupplementContainerOffset(view.bounds.size.height)
            } else {
                self.supplementBottomAnchor.constant = -regularSupplementContainerOffset
            }
        } else {
            self.supplementBottomAnchor.constant = -dismissedSupplementContainerOffset
        }

        containerState.isPresentingPlaybackControls = isCompact
        containerState.supplementOffset = supplementBottomAnchor.constant

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
            ) {
                self.view.layoutIfNeeded()
            }
        } else if isCompact {
            UIView.animate(
                withDuration: 0.75,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.4,
                options: .allowUserInteraction
            ) {
                self.view.layoutIfNeeded()
            }
        } else {
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                options: [.curveEaseInOut, .allowUserInteraction]
            ) {
                self.view.layoutIfNeeded()
            }

//            UIView.animate(
//                withDuration: 0.75,
//                delay: 0,
//                usingSpringWithDamping: 0.8,
//                initialSpringVelocity: 0.4,
//                options: .allowUserInteraction
//            ) {
//                self.view.layoutIfNeeded()
//            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        self.isCompact = UIDevice.isPhone && view.bounds.size.isPortrait

        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        addChild(playerViewController)
        view.addSubview(playerView)
        playerViewController.didMove(toParent: self)

        addChild(playbackControlsViewController)
        view.addSubview(playbackControlsView)
        playbackControlsViewController.didMove(toParent: self)
        playbackControlsView.backgroundColor = .clear

        addChild(supplementContainerViewController)
        view.addSubview(supplementContainerView)
        supplementContainerViewController.didMove(toParent: self)
        supplementContainerView.backgroundColor = .green.withAlphaComponent(0.2)
    }

    private func setupConstraints() {
        playerCompactConstraints = [
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: supplementContainerView.topAnchor),
        ]
        playerRegularConstraints = [
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]

        let shouldBeCompact = UIDevice.isPhone && view.bounds.size.isPortrait

        if shouldBeCompact {
            NSLayoutConstraint.activate(playerCompactConstraints)
        } else {
            NSLayoutConstraint.activate(playerRegularConstraints)
        }

        supplementBottomAnchor = supplementContainerView.topAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -dismissedSupplementContainerOffset
        )
        containerState.supplementOffset = supplementBottomAnchor.constant

        let constant = shouldBeCompact ?
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
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        adjustContraints(shouldBeCompact: UIDevice.isPhone && size.isPortrait, in: size)
    }

    private func adjustContraints(shouldBeCompact: Bool, in newSize: CGSize) {
        self.isCompact = shouldBeCompact

        if shouldBeCompact {
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

        containerState.supplementOffset = supplementHeightAnchor.constant
    }
}
