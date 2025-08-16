//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import UIKit

struct VideoPlayerContainerView<Player: View, PlaybackControls: View>: UIViewControllerRepresentable {

    @EnvironmentObject
    private var manager: MediaPlayerManager

    private let player: Player
    private let playbackControls: PlaybackControls

    init(
        @ViewBuilder player: () -> Player,
        @ViewBuilder playbackControls: () -> PlaybackControls
    ) {
        self.player = player()
        self.playbackControls = playbackControls()
    }

    func makeUIViewController(context: Context) -> UIVideoPlayerContainerViewController<Player, PlaybackControls> {
        UIVideoPlayerContainerViewController(
            manager: manager,
            player: player,
            playbackControls: playbackControls,
            selectedSupplement: context.environment.selectedMediaPlayerSupplement
        )
    }

    func updateUIViewController(
        _ uiViewController: UIVideoPlayerContainerViewController<Player, PlaybackControls>,
        context: Context
    ) {
        uiViewController.selectedSupplement = context.environment.selectedMediaPlayerSupplement
    }
}

class UIVideoPlayerContainerViewController<Player: View, PlaybackControls: View>: UIViewController {

    private var playerViewController: UIHostingController<Player>
    private var playbackControlsViewController: UIHostingController<PlaybackControls>
    private var supplementContainerViewController: UIHostingController<AnyView>

    private var playerView: UIView { playerViewController.view }
    private var playbackControlsView: UIView { playbackControlsViewController.view }
    private var supplementContainerView: UIView { supplementContainerViewController.view }

    private var supplementCompactConstraints: [NSLayoutConstraint] = []
    private var supplementRegularConstraints: [NSLayoutConstraint] = []
    private var playerOnlyConstraints: [NSLayoutConstraint] = []
    private var playbackControlsConstraits: [NSLayoutConstraint] = []

    let manager: MediaPlayerManager

    var selectedSupplement: Binding<AnyMediaPlayerSupplement?>
//    {
//        didSet {
//            if oldValue?.id != selectedSupplement?.id {
//                updateSupplement(oldSupplement: oldValue)
//            }
//        }
//    }

    init(
        manager: MediaPlayerManager,
        player: Player,
        playbackControls: PlaybackControls,
        selectedSupplement: Binding<AnyMediaPlayerSupplement?>
    ) {
        self.manager = manager
        self.playerViewController = UIHostingController(rootView: player, ignoreSafeArea: true)
        self.playbackControlsViewController = UIHostingController(rootView: playbackControls, ignoreSafeArea: true)
        self.supplementContainerViewController = UIHostingController(ignoreSafeArea: true) {
            SupplementContainerView()
                .environmentObject(manager)
                .environment(\.selectedMediaPlayerSupplement, selectedSupplement)
                .eraseToAnyView()
        }

        self.selectedSupplement = selectedSupplement

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        addChild(playerViewController)
        view.addSubview(playerView)
        playerViewController.didMove(toParent: self)
        playerView.translatesAutoresizingMaskIntoConstraints = false

        addChild(playbackControlsViewController)
        view.addSubview(playbackControlsView)
        playbackControlsViewController.didMove(toParent: self)
        playbackControlsView.translatesAutoresizingMaskIntoConstraints = false
        playbackControlsView.backgroundColor = .clear

        addChild(supplementContainerViewController)
        view.addSubview(supplementContainerView)
        supplementContainerViewController.didMove(toParent: self)
        supplementContainerView.translatesAutoresizingMaskIntoConstraints = false
        supplementContainerView.backgroundColor = .red.withAlphaComponent(0.5)
    }

    private func setupConstraints() {
        playerOnlyConstraints = [
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]

        NSLayoutConstraint.activate(playerOnlyConstraints)

        NSLayoutConstraint.activate([
            supplementContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            supplementContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            supplementContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            supplementContainerView.heightAnchor.constraint(equalToConstant: 50),
        ])

        playbackControlsConstraits = [
            playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playbackControlsView.topAnchor.constraint(equalTo: view.topAnchor),
            playbackControlsView.bottomAnchor.constraint(equalTo: supplementContainerView.topAnchor),
        ]

        NSLayoutConstraint.activate(playbackControlsConstraits)
    }

//    private func updateSupplement(oldSupplement: AnyMediaPlayerSupplement? = nil) {
//        if let supplement = selectedSupplement {
//            let supplementHostingController = UIHostingController(rootView: supplement.supplement.videoPlayerBody().eraseToAnyView())
//            addChild(supplementHostingController)
//            view.insertSubview(supplementHostingController.view, belowSubview: playbackControlsView)
//            supplementHostingController.didMove(toParent: self)
//            supplementHostingController.view.translatesAutoresizingMaskIntoConstraints = false
//            self.supplementViewController = supplementHostingController
//            setupSupplementConstraints()
//            updateConstraintsForSupplement()
//        } else {
//            guard let oldSupplement = oldSupplement else {
//                updateConstraintsForPlayerOnly()
//                return
//            }
//            let supplementHostingController = UIHostingController(rootView: oldSupplement.supplement.videoPlayerBody().eraseToAnyView())
//            addChild(supplementHostingController)
//            view.insertSubview(supplementHostingController.view, belowSubview: playbackControlsView)
//            supplementHostingController.didMove(toParent: self)
//            supplementHostingController.view.translatesAutoresizingMaskIntoConstraints = false
//            self.supplementViewController = supplementHostingController
//            setupSupplementConstraints()
//            updateConstraintsForPlayerOnly()
//        }
//    }

//    private func setupSupplementConstraints() {
//        guard let supplementView else { return }
//
//        supplementCompactConstraints = [
//            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            playerView.topAnchor.constraint(equalTo: view.topAnchor),
//            playerView.heightAnchor.constraint(equalToConstant: 250),
//            supplementTitleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            supplementTitleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            supplementTitleView.topAnchor.constraint(equalTo: playerView.bottomAnchor),
//            supplementView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            supplementView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            supplementView.topAnchor.constraint(equalTo: supplementTitleView.bottomAnchor),
//            supplementView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ]
//
//        supplementRegularConstraints = [
//            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            playerView.topAnchor.constraint(equalTo: view.topAnchor),
//            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            supplementTitleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            supplementTitleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            supplementTitleView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
    ////            supplementTitleView.bottomAnchor.constraint(equalTo: supplementView.topAnchor),
//            supplementView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            supplementView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            supplementView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//        ]
//    }

    private func updateConstraintsForSupplement() {
        NSLayoutConstraint.deactivate(playerOnlyConstraints)
        if view.bounds.width < 300 || view.bounds.width < view.bounds.height {
            NSLayoutConstraint.deactivate(supplementRegularConstraints)
            NSLayoutConstraint.activate(supplementCompactConstraints)
        } else {
            NSLayoutConstraint.deactivate(supplementCompactConstraints)
            NSLayoutConstraint.activate(supplementRegularConstraints)
        }
//        animateLayout()
    }

    private func updateConstraintsForPlayerOnly() {
        NSLayoutConstraint.deactivate(supplementCompactConstraints)
        NSLayoutConstraint.deactivate(supplementRegularConstraints)
        NSLayoutConstraint.activate(playerOnlyConstraints)
//        animateLayout(isRemoving: true)
    }

//    private func animateLayout(isRemoving: Bool = false) {
//        if isRemoving {
//            self.supplementViewController?.view.transform = .identity
//        } else {
//            self.supplementViewController?.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
//        }
//
//        UIView.animate(
//            withDuration: 0.4,
//            delay: 0,
//            usingSpringWithDamping: 0.8,
//            initialSpringVelocity: 1,
//            options: .curveEaseInOut,
//            animations: {
//                if isRemoving {
//                    self.supplementViewController?.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
//                } else {
//                    self.supplementViewController?.view.transform = .identity
//                }
//                self.view.layoutIfNeeded()
//            },
//            completion: { _ in
//                if isRemoving {
//                    self.supplementViewController?.willMove(toParent: nil)
//                    self.supplementViewController?.view.removeFromSuperview()
//                    self.supplementViewController?.removeFromParent()
//                    self.supplementViewController = nil
//                }
//            }
//        )
//    }

//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        super.viewWillTransition(to: size, with: coordinator)
//        coordinator.animate(alongsideTransition: { _ in
//            if self.selectedSupplement != nil {
//                self.updateConstraintsForSupplement()
//            }
//        }, completion: nil)
//    }
}

struct SupplementContainerView: View {

    @Environment(\.selectedMediaPlayerSupplement)
    @Binding
    private var selectedSupplement: AnyMediaPlayerSupplement?

    @EnvironmentObject
    private var manager: MediaPlayerManager

    var body: some View {
        VStack {
            SupplementTitleHStack()

            if let selectedSupplement {
                selectedSupplement.supplement
                    .videoPlayerBody()
                    .eraseToAnyView()
                    .id(selectedSupplement.id)
                    .transition(.opacity.animation(.linear(duration: 0.1)))
            }
        }
    }
}
