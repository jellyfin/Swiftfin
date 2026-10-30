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

// TODO: pause when center tapped when overlay dismissed
//       - can be done entirely on playback controls layer
// TODO: account for gesture state active when item changes

extension VideoPlayer {

    struct Container<Player: View, PlaybackControls: View>: PlatformViewControllerRepresentable {

        private let viewState: ViewState
        private let mediaSession: MediaSession
        private let videoSize: () -> CGSize
        private let player: (VideoLayout) -> Player
        private let playbackControls: PlaybackControls

        init(
            viewState: ViewState,
            mediaSession: MediaSession,
            videoSize: @escaping () -> CGSize,
            @ViewBuilder player: @escaping (VideoLayout) -> Player,
            @ViewBuilder playbackControls: @escaping () -> PlaybackControls
        ) {
            self.viewState = viewState
            self.mediaSession = mediaSession
            self.videoSize = videoSize
            self.player = player
            self.playbackControls = playbackControls()
        }

        func makeUIViewController(context: Context) -> UIContainerViewController {
            let playerView = { (videoLayout: VideoLayout) in
                player(videoLayout)
                    .eraseToAnyView()
            }

            let playbackControlsView = playbackControls
                .eraseToAnyView()

            return UIContainerViewController(
                viewState: viewState,
                mediaSession: mediaSession,
                videoSize: videoSize,
                player: playerView,
                playbackControls: playbackControlsView
            )
        }

        static func dismantleUIViewController(_ controller: UIContainerViewController, coordinator: ()) {
            // A surface can be rebuilt or handed to PiP without ending its media session.
            controller.detachSurface()
        }

        func updateUIViewController(
            _ uiViewController: UIContainerViewController,
            context: Context
        ) {}
    }

    // MARK: - UIContainerViewController

    class UIContainerViewController: UIViewController {

        typealias ViewState = VideoPlayer.ViewState

        private var viewLayout: ViewLayout {
            ViewLayout(size: view.bounds.size, traits: traitCollection)
        }

        private struct LayoutEnvironment: ViewModifier {

            @Environment(ViewState.self)
            private var viewState

            func body(content: Content) -> some View {
                content
                    .layoutContainer(size: viewState.layoutSize)
            }
        }

        // MARK: - Views

        private struct PlayerContainerView: View {

            @Environment(ViewState.self)
            private var viewState

            let player: (VideoLayout) -> AnyView
            let videoSize: () -> CGSize

            private var shouldPresentDimOverlay: Bool {
                viewState.visibleElements.contains(.dimming)
            }

            var body: some View {
                VideoViewport(videoSize: videoSize) { videoLayout in
                    player(videoLayout)
                        #if os(iOS)
                            .overlay(Color.black.opacity(shouldPresentDimOverlay ? 0.5 : 0.0))
                        #endif
                        .overlay {
                            Group {
                                if viewState.isPresentingFullScreenSupplement {
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
                #if os(iOS)
                .overlay {
                        VideoZoomBorder(isVisible: viewState.zoom.isFillBorderPresented)
                    }
                #endif
            }
        }

        private struct PlaybackControlsContainerView: View {

            @Environment(ViewState.self)
            private var viewState

            let playbackControls: AnyView

            private var panGestureDirection: Direction {
                if viewState.canPanZoom {
                    .all
                } else {
                    if viewState.isPresentingSupplement {
                        .vertical
                    } else {
                        if viewState.isPresentingControls {
                            if viewState.supplements.isEmpty {
                                []
                            } else {
                                Direction.up
                            }
                        } else {
                            .allButDown
                        }
                    }
                }
            }

            var body: some View {
                Group {
                    #if os(iOS)
                    SafeRegion(systemInsets: .none) {
                        SafeRegionItem {
                            GestureView()
                                .environment(\.panGestureDirection, panGestureDirection)
                        }
                        .ignoresSafeRegion(.all)

                        SafeRegionItem { playbackControls }
                            .ignoresSafeRegion(.all)
                    }
                    #else
                    OverlayToastView(proxy: viewState.toastProxy) { playbackControls }
                    #endif
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
                                viewState.containerView?.handlePinchGesture(
                                    scale: $0,
                                    location: $1,
                                    state: $2
                                )
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

        #if os(iOS)
        private let zoomHaptic = UIImpactFeedbackGenerator(style: .light)
        private var zoomStopFeedback = VideoZoom.StopFeedback()

        func prepareZoomHaptics() {
            zoomStopFeedback = VideoZoom.StopFeedback(stop: viewState.zoom.stop)
            zoomHaptic.prepare()
        }

        func updateZoomHaptics() {
            guard let transform = viewState.zoom.transform,
                  zoomStopFeedback.update(scale: transform.scale, stop: viewState.zoom.stop)
            else { return }

            zoomHaptic.impactOccurred()
            zoomHaptic.prepare()
        }
        #endif

        private lazy var initialHitBlockView: UIView = {
            let view = UIView(frame: .zero)
            view.translatesAutoresizingMaskIntoConstraints = false

            return view
        }()

        private lazy var playerViewController: HostingController<AnyView> = {
            let controller = HostingController(
                content: PlayerContainerView(player: player, videoSize: videoSize)
                    .modifier(LayoutEnvironment())
                    .environment(viewState)
                    .environmentObject(viewState.focusCoordinator)
                    .environment(mediaSession)
                    .eraseToAnyView()
            )

            #if os(iOS)
            controller.disableSafeArea = true
            #endif
            controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            return controller
        }()

        private lazy var playbackControlsViewController: HostingController<AnyView> = {
            let controller = HostingController(
                content: PlaybackControlsContainerView(playbackControls: playbackControls)
                    .modifier(LayoutEnvironment())
                    .environment(viewState)
                    .environmentObject(viewState.focusCoordinator)
                    .environment(mediaSession)
                    .eraseToAnyView()
            )

            controller.disableSafeArea = true
            controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            return controller
        }()

        #if os(tvOS)
        private lazy var supplementContainerViewController: HostingController<AnyView> = {
            let content = SupplementContainerView()
                .modifier(LayoutEnvironment())
                .environment(viewState)
                .environmentObject(viewState.focusCoordinator)
                .environment(mediaSession)
                .eraseToAnyView()

            let controller = HostingController(content: content)
            controller.disableSafeArea = true
            controller.automaticallyAllowUIKitAnimationsForNextUpdate = true
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            return controller
        }()

        private lazy var overlayActionsViewController: HostingController<AnyView> = {
            let controller = HostingController(
                content: OverlayActions()
                    .modifier(LayoutEnvironment())
                    .environment(viewState)
                    .environmentObject(viewState.focusCoordinator)
                    .eraseToAnyView()
            )

            controller.disableSafeArea = true
            controller.sizingOptions = .intrinsicContentSize
            controller.view.translatesAutoresizingMaskIntoConstraints = false

            return controller
        }()

        #endif

        private var playerView: UIView {
            playerViewController.view
        }

        func playerLocation(fromControls point: CGPoint) -> CGPoint {
            playerView.convert(point, from: playbackControlsView)
        }

        private var playbackControlsView: UIView {
            playbackControlsViewController.view
        }

        #if os(tvOS)
        private var supplementContainerView: UIView {
            supplementContainerViewController.view
        }

        private var overlayActionsView: UIView {
            overlayActionsViewController.view
        }

        #endif

        // MARK: - Constants

        private var availableSupplementHeight: CGFloat {
            max(0, view.bounds.height - view.safeAreaInsets.top)
        }

        private func supplementContainerOffset(
            isCompact: Bool? = nil
        ) -> CGFloat {
            let isCompact = isCompact ?? viewState.isCompact
            let availableHeight = availableSupplementHeight

            if !isCompact, viewState.selectedSupplement?.presentationStyle == .expanded {
                return availableHeight
            }

            if !isCompact, !viewLayout.isLarge {
                return min(availableHeight, 200 + viewLayout.edgePadding * 2)
            }

            let bottomInset = min(view.safeAreaInsets.bottom, availableHeight)
            let contentHeight = availableHeight - bottomInset
            let fraction: CGFloat = isCompact ? 0.6 : 1.0 / 3.0
            let preferredHeight = contentHeight * fraction + bottomInset + viewLayout.edgePadding * 2

            return min(availableHeight, max(dismissedSupplementContainerOffset, preferredHeight))
        }

        private var dismissedSupplementContainerOffset: CGFloat {
            min(availableSupplementHeight, viewLayout.isLarge ? 120 : 50.0 + viewLayout.edgePadding * 2)
        }

        private let compactMinimumTranslation: CGFloat = 100.0
        private let regularMinimumTranslation: CGFloat = 50.0

        // MARK: - Constraints

        private var playerCompactBottomAnchor: NSLayoutConstraint?
        private var playerRegularBottomAnchor: NSLayoutConstraint?
        #if os(tvOS)
        private var supplementHeightAnchor: NSLayoutConstraint?
        private var supplementBottomAnchor: NSLayoutConstraint?
        #endif

        private var supplementHeight: CGFloat = 0 {
            didSet {
                #if os(tvOS)
                supplementHeightAnchor?.constant = supplementHeight
                #else
                updateSupplementLayoutBounds()
                #endif
            }
        }

        private var supplementOffset: CGFloat = 0 {
            didSet {
                #if os(tvOS)
                supplementBottomAnchor?.constant = supplementOffset
                #else
                updateSupplementLayoutBounds()
                #endif
            }
        }

        #if os(iOS)
        private func updateSupplementLayoutBounds() {
            viewState.supplementHeight = supplementHeight
            viewState.supplementVisibleHeight = max(0, -supplementOffset)

            // Keep playback buttons aligned while the panel moves.
            let centerOffset = compactPlayerOverlap.map { max(50, $0) } ?? dismissedSupplementContainerOffset
            let bottomInset = -supplementOffset - centerOffset

            viewState.playbackButtonsInsets = EdgeInsets(
                top: max(0, -bottomInset),
                leading: 0,
                bottom: max(0, bottomInset),
                trailing: 0
            )
        }
        #endif

        private var compactPlayerAnchorOffset: CGFloat {
            #if os(tvOS)
            compactPlayerBottomOffset
            #else
            supplementOffset + compactPlayerBottomOffset
            #endif
        }

        private var compactPlayerBottomOffset: CGFloat {
            compactPlayerOverlap ?? dismissedSupplementContainerOffset
        }

        private var compactPlayerOverlap: CGFloat? {
            guard viewState.isCompact, supplementHeight > 0
            else {
                return nil
            }

            let supplementContainerHeight = supplementHeight
            let offsetPercentage = 1 - clamp(supplementOffset.magnitude / supplementContainerHeight, min: 0, max: 1)

            return (dismissedSupplementContainerOffset + viewLayout.edgePadding) * offsetPercentage
        }

        private let logger = Logger.swiftfin()
        private let mediaSession: MediaSession
        private let videoSize: () -> CGSize
        private let player: (VideoLayout) -> AnyView
        private let playbackControls: AnyView
        let viewState: ViewState

        private var isDismissing = false
        private var didInitiallyAppear: Bool = false
        private var lastSupplementLayout: (layout: ViewLayout, safeAreaInsets: UIEdgeInsets)?

        #if os(tvOS)
        let onPressEvent = OnPressEvent()
        private var lastTouchPokeTime: CFTimeInterval = 0
        private var pendingPlaybackFocusRequest: UUID?
        #endif

        init(
            viewState: ViewState,
            mediaSession: MediaSession,
            videoSize: @escaping () -> CGSize,
            player: @escaping (VideoLayout) -> AnyView,
            playbackControls: AnyView
        ) {
            self.viewState = viewState
            self.mediaSession = mediaSession
            self.videoSize = videoSize
            self.player = player
            self.playbackControls = playbackControls

            super.init(nibName: nil, bundle: nil)

            viewState.containerView = self
            viewState.connect(mediaSession: mediaSession)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private var verticalPanGestureStartConstant: CGFloat?
        private var isPanning: Bool = false
        private var didStartPanningWithSupplement: Bool = false
        private var didStartPanningUpWithoutOverlay: Bool = false

        // MARK: - Supplement Pan Action

        func handleSupplementPanAction(
            translation: CGPoint,
            velocity: CGFloat,
            state: UIGestureRecognizer.State
        ) {
            guard viewState.supplements.isNotEmpty else {
                cancelSupplementPan()
                return
            }
            guard state == .began || isPanning,
                  let playerCompactBottomAnchor
            else { return }

            // The pan owns layout until the final selection is committed below.
            isPanning = true

            if state == .began {
                self.view.layer.removeAllAnimations()
                didStartPanningWithSupplement = viewState.isPresentingSupplement
                verticalPanGestureStartConstant = supplementOffset
                didStartPanningUpWithoutOverlay = !viewState.isPresentingControls

                if didStartPanningUpWithoutOverlay {
                    viewState.showControls()
                }
            }

            if state == .began || state == .changed {
                let minimumTranslation =
                    -((viewState.isCompact ? compactMinimumTranslation : regularMinimumTranslation) +
                        dismissedSupplementContainerOffset
                    )

                let shouldHaveSupplementPresented = supplementOffset < minimumTranslation

                if shouldHaveSupplementPresented, !viewState.isPresentingSupplement {
                    viewState.selectedSupplementID = viewState.supplements.first?.id
                } else if !shouldHaveSupplementPresented, viewState.isPresentingSupplement {
                    viewState.selectedSupplementID = nil
                }

                supplementHeight = supplementContainerOffset()
            } else {
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
                    viewState.selectedSupplementID = viewState.supplements.first?.id
                }

                isPanning = false
                presentSupplementContainer(viewState.isPresentingSupplement)

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

            let newOffset = verticalPanGestureStartConstant + translation.y

            let clampedOffset = clamp(
                newOffset,
                min: -supplementHeight,
                max: -dismissedSupplementContainerOffset
            )

            if newOffset < clampedOffset {
                let excess = clampedOffset - newOffset
                let resistance = pow(excess, 0.7)
                supplementOffset = max(-availableSupplementHeight, clampedOffset - resistance)
            } else if newOffset > -dismissedSupplementContainerOffset {
                let excess = newOffset - clampedOffset
                let resistance = pow(excess, 0.5)

                supplementOffset = clamp(
                    clampedOffset + resistance,
                    min: -dismissedSupplementContainerOffset,
                    max: -min(50, dismissedSupplementContainerOffset)
                )
            } else {
                supplementOffset = clampedOffset
            }

            playerCompactBottomAnchor.constant = compactPlayerAnchorOffset
        }

        func cancelSupplementPan() {
            guard isPanning else { return }

            isPanning = false
            verticalPanGestureStartConstant = nil
            viewState.setInteraction(.pan, active: false)

            #if os(iOS)
            viewState.panHandlingAction = nil
            #endif

            presentSupplementContainer(viewState.isPresentingSupplement)
        }

        // MARK: - present

        func presentSupplementContainer(_ didPresent: Bool) {
            guard !isPanning, let playerCompactBottomAnchor
            else { return }

            let presentedOffset = supplementContainerOffset()
            #if os(iOS)
            withAnimation(.spring(response: viewState.isCompact ? 0.75 : 0.6, dampingFraction: 0.8)) {
                supplementHeight = presentedOffset
                supplementOffset = didPresent ? -presentedOffset : -dismissedSupplementContainerOffset
            }
            #else
            supplementHeight = presentedOffset
            supplementOffset = didPresent ? -presentedOffset : -dismissedSupplementContainerOffset
            #endif

            playerCompactBottomAnchor.constant = compactPlayerAnchorOffset

            let completion: (Bool) -> Void

            #if os(tvOS)
            let supplementID = viewState.selectedSupplementID
            let playbackFocusRequest = !didPresent && viewState.isPresentingProgress ? UUID() : nil
            pendingPlaybackFocusRequest = playbackFocusRequest

            completion = { [weak self] finished in
                guard let self, finished else { return }

                if let supplementID {
                    viewState.focusSupplementIfNeeded(supplementID)
                } else if let playbackFocusRequest {
                    restorePlaybackFocusIfNeeded(playbackFocusRequest)
                }
            }
            #else
            completion = { _ in }
            #endif

            UIView.animate(
                withDuration: viewState.isCompact ? 0.75 : 0.6,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.4,
                options: .allowUserInteraction
            ) { [weak self] in
                self?.view.layoutIfNeeded()
            } completion: { completion($0) }
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
        }

        // MARK: - viewDidLoad

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .black

            viewState.isCompact = viewLayout.usesCompactPlayer

            setupOnLoadViews()
            setupOnLoadConstraints()

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

            #if os(tvOS)
            let compactBottomAnchor = supplementContainerView.topAnchor
            #else
            let compactBottomAnchor = view.bottomAnchor
            #endif
            let bottomAnchor = playerView.bottomAnchor.constraint(
                equalTo: compactBottomAnchor,
                constant: compactPlayerAnchorOffset
            )

            playerCompactBottomAnchor = bottomAnchor
            playerRegularBottomAnchor = playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

            NSLayoutConstraint.activate([
                playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playerView.topAnchor.constraint(equalTo: view.topAnchor),
            ])

            playerCompactBottomAnchor?.isActive = viewState.isCompact
            playerRegularBottomAnchor?.isActive = !viewState.isCompact
        }

        private func setupOnLoadViews() {
            addChild(playbackControlsViewController)
            view.addSubview(playbackControlsView)
            playbackControlsViewController.didMove(toParent: self)
            playbackControlsView.backgroundColor = .clear

            #if os(tvOS)
            addChild(supplementContainerViewController)
            view.addSubview(supplementContainerView)
            supplementContainerViewController.didMove(toParent: self)
            supplementContainerView.backgroundColor = .clear

            addChild(overlayActionsViewController)
            view.addSubview(overlayActionsView)
            overlayActionsViewController.didMove(toParent: self)
            overlayActionsView.backgroundColor = .clear
            #endif

            view.addSubview(initialHitBlockView)
            view.bringSubviewToFront(initialHitBlockView)
        }

        private func setupOnLoadConstraints() {

            supplementHeight = supplementContainerOffset(isCompact: viewLayout.usesCompactPlayer)
            supplementOffset = -dismissedSupplementContainerOffset

            #if os(tvOS)
            let bottomAnchor = supplementContainerView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: supplementOffset)
            supplementBottomAnchor = bottomAnchor
            let heightAnchor = supplementContainerView.heightAnchor.constraint(equalToConstant: supplementHeight)
            supplementHeightAnchor = heightAnchor

            NSLayoutConstraint.activate([
                supplementContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                supplementContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                bottomAnchor,
                heightAnchor,
            ])

            let playbackControlsBottomAnchor = playbackControlsView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -dismissedSupplementContainerOffset
            )
            playbackControlsBottomAnchor.priority = .defaultHigh

            NSLayoutConstraint.activate([
                playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playbackControlsView.topAnchor.constraint(equalTo: view.topAnchor),
                playbackControlsBottomAnchor,
                playbackControlsView.bottomAnchor.constraint(
                    lessThanOrEqualTo: overlayActionsView.topAnchor,
                    constant: -viewLayout.edgePadding
                ),
                overlayActionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: viewLayout.edgePadding),
                overlayActionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -viewLayout.edgePadding),
                overlayActionsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -viewLayout.edgePadding),
            ])
            #else
            NSLayoutConstraint.activate([
                playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                playbackControlsView.topAnchor.constraint(equalTo: view.topAnchor),
                playbackControlsView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
            #endif

            NSLayoutConstraint.activate([
                initialHitBlockView.topAnchor.constraint(equalTo: view.topAnchor),
                initialHitBlockView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                initialHitBlockView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                initialHitBlockView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()

            updateSystemSafeArea()
            let layout = viewLayout
            let safeAreaInsets = view.safeAreaInsets
            guard playerCompactBottomAnchor != nil,
                  lastSupplementLayout?.layout != layout || lastSupplementLayout?.safeAreaInsets != safeAreaInsets
            else { return }

            lastSupplementLayout = (layout, safeAreaInsets)
            if viewState.layoutSize != layout.size {
                viewState.layoutSize = layout.size
            }
            cancelSupplementPan()
            adjustConstraints(isCompact: layout.usesCompactPlayer)
        }

        override func viewSafeAreaInsetsDidChange() {
            super.viewSafeAreaInsetsDidChange()
            updateSystemSafeArea()
        }

        private func updateSystemSafeArea() {
            // Capture system insets before the hosting controller disables them.
            let insets = view.safeAreaInsets
            let isRTL = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
            let system = EdgeInsets(
                top: insets.top,
                leading: isRTL ? insets.right : insets.left,
                bottom: insets.bottom,
                trailing: isRTL ? insets.left : insets.right
            )

            if viewState.systemInsets != system {
                viewState.systemInsets = system
            }
        }

        private func adjustConstraints(isCompact: Bool) {
            viewState.isCompact = isCompact

            guard let playerCompactBottomAnchor
            else { return }

            let presentedOffset = supplementContainerOffset(isCompact: isCompact)

            if isCompact {
                playerRegularBottomAnchor?.isActive = false
                playerCompactBottomAnchor.isActive = true
            } else {
                playerCompactBottomAnchor.isActive = false
                playerRegularBottomAnchor?.isActive = true
            }

            supplementOffset = viewState
                .isPresentingSupplement ? -presentedOffset : -dismissedSupplementContainerOffset
            supplementHeight = presentedOffset

            playerCompactBottomAnchor.constant = compactPlayerAnchorOffset
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            // An interactive dismissal can be cancelled.
            isDismissing = false
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            #if os(iOS)
            viewState.cancelTapGesture()
            #endif

            isDismissing = false
            var ancestor: UIViewController? = self

            while let controller = ancestor {
                if controller.isBeingDismissed || controller.isMovingFromParent {
                    isDismissing = true
                    break
                }

                ancestor = controller.parent
            }
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)

            // Covering the player with a full-screen sheet does not end playback.
            if isDismissing {
                didDismiss()
            }
        }

        func didDismiss() {
            guard !viewState.isBeingDismissed else { return }

            viewState.isBeingDismissed = true
            let pictureInPicture = mediaSession.player as? MediaPlayerPictureInPictureProviding

            if pictureInPicture?.isPiPActive != true, pictureInPicture?.isPiPTransitioning != true {
                mediaSession.stop()
            }
        }

        func detachSurface() {
            guard viewState.containerView === self else { return }

            viewState.containerView = nil
            viewState.disconnect()
        }

        // MARK: - tvOS

        #if os(tvOS)
        override var preferredFocusEnvironments: [UIFocusEnvironment] {
            if viewState.isSupplementFocusPending {
                return [supplementContainerViewController]
            }

            if viewState.isPresentingProgress {
                return [playbackControlsViewController]
            }

            return super.preferredFocusEnvironments
        }

        func focusSupplementContent() {
            // Tabs stay disabled while content focus is pending. Enter the hosting
            // hierarchy from the common ancestor of the current and requested focus.
            setNeedsFocusUpdate()
            updateFocusIfNeeded()
        }

        private func restorePlaybackFocusIfNeeded(_ request: UUID) {
            guard pendingPlaybackFocusRequest == request else { return }

            pendingPlaybackFocusRequest = nil

            // Retry only if the controls could not receive focus during dismissal.
            // They may already be focused when a layout animation starts.
            guard viewState.isPresentingProgress,
                  (UIFocusSystem.focusSystem(for: view)?.focusedItem as? UIView)?.isDescendant(of: playbackControlsView) != true
            else { return }

            view.window?.setNeedsFocusUpdate()
            updateFocusIfNeeded()
        }

        override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
            super.didUpdateFocus(in: context, with: coordinator)

            // Complete the handoff synchronously when focus leaves the supplement.
            // A late animation completion must not undo navigation within the player
            // or into another focus environment, such as a menu.
            if let nextFocusedView = context.nextFocusedView,
               !nextFocusedView.isDescendant(of: supplementContainerView)
            {
                pendingPlaybackFocusRequest = nil
            }
        }

        override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
            guard super.shouldUpdateFocus(in: context) else { return false }

            // A lone title is an entry point, not a focus stop. Wait for its content
            // to appear before handing focus to the supplement's preferred control.
            if !viewState.isPresentingSupplement,
               viewState.visibleElements.contains(.supplements),
               let supplement = viewState.singleSupplement,
               context.focusHeading.contains(.down),
               context.nextFocusedView?.isDescendant(of: supplementContainerView) == true
            {
                DispatchQueue.main.async { [weak self] in
                    guard let self,
                          !viewState.isPresentingSupplement,
                          viewState.visibleElements.contains(.supplements),
                          viewState.singleSupplement?.id == supplement.id
                    else { return }

                    viewState.selectedSupplementID = supplement.id
                }

                return false
            }

            return true
        }

        override func updateProperties() {
            super.updateProperties()
            supplementContainerView.isUserInteractionEnabled = viewState.visibleElements.contains(.supplements)
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)

            guard !(viewState.presentation == .hidden && viewState.isPresentingOverlayActions) else { return }

            let now = CACurrentMediaTime()
            guard now - lastTouchPokeTime > 1.0 else { return }

            lastTouchPokeTime = now

            if mediaSession.item.isLiveStream {
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
            guard mediaSession.canControlPlayback else { return }

            if viewState.isScrubbing {
                viewState.cancelScrub()
                return
            }

            if viewState.presentation == .hidden {
                if mediaSession.playbackRequestStatus == .paused {
                    mediaSession.setPlaybackRequestStatus(status: .playing)
                }

                viewState.showControls()
            } else {
                switch mediaSession.playbackRequestStatus {
                case .playing:
                    mediaSession.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    mediaSession.setPlaybackRequestStatus(status: .playing)
                }
            }

            viewState.refreshAutoDismiss()
        }

        private func handleSelectEnded(_ press: UIPress, event: UIPressesEvent?) {
            if viewState.isOverlayActionFocused {
                forwardPressesEnded([press], event: event)
                return
            }

            if viewState.presentation == .hidden {
                viewState.showControls()
                return
            }

            if viewState.isScrubbing {
                viewState.commitScrub(resumePlayback: true)
            } else if viewState.isProgressBarFocused {
                guard mediaSession.canControlPlayback else { return }

                switch mediaSession.playbackRequestStatus {
                case .playing:
                    mediaSession.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    mediaSession.setPlaybackRequestStatus(status: .playing)
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
                mediaSession.stop()
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
