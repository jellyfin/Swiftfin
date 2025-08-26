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
                .eraseToAnyView()
        )
        controller.disablesSafeArea = true
        controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        return controller
    }()

    private lazy var playbackControlsViewController: HostingController<AnyView> = {
        let controller = HostingController(
            content: playbackControls
                .environmentObject(containerState)
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

    // MARK: - didPresent

    func didPresent(supplement: AnyMediaPlayerSupplement?) {

        let didPresent = supplement != nil

        if didPresent {
            self.supplementBottomAnchor.constant = -(500 + EdgeInsets.edgePadding * 2)
        } else {
            self.supplementBottomAnchor.constant = -(100 + EdgeInsets.edgePadding)
        }

        containerState.isPresentingPlaybackControls = !didPresent
        containerState.supplementOffset = supplementBottomAnchor.constant

        // TODO: different values based on velocity, translation left
        UIView.animate(
            withDuration: 0.75,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.4,
            options: .allowUserInteraction
        ) {
            self.view.layoutIfNeeded()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

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
        playerRegularConstraints = [
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]

        NSLayoutConstraint.activate(playerRegularConstraints)

        supplementBottomAnchor = supplementContainerView.topAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -(100 + EdgeInsets.edgePadding)
        )
        containerState.supplementOffset = supplementBottomAnchor.constant

        let constant = (500 + EdgeInsets.edgePadding * 2)
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
}
