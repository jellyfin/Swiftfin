//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVKit
import Combine
import Factory
import JellyfinAPI
import Logging
import SwiftUI
import Transmission

// TODO: remove

struct NativeVideoPlayer: View {

    @Environment(\.presentationCoordinator)
    private var presentationCoordinator

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    @LazyState
    private var proxy: AVMediaPlayerProxy

    @Router
    private var router

    init() {
        self._proxy = .init(wrappedValue: AVMediaPlayerProxy())
    }

    var body: some View {
        ZStack {

            Color.black

            switch manager.state {
            case .playback:
                NativeVideoPlayerView(proxy: proxy, manager: manager)
                #if !os(tvOS)
                    // Without insight into AVKit overlay presentation, only
                    // present the button during its standalone window.
                        .overlay(alignment: .bottomTrailing) {
                            if let segmentObserver = manager.segmentObserver {
                                SkipSegmentButton(
                                    observer: segmentObserver,
                                    isPresentingOverlay: false
                                )
                                .padding(.trailing, 80)
                                .padding(.bottom, 120)
                            }
                        }
                #endif
            default:
                ProgressView()
            }
        }
        .onAppear {
            manager.proxy = proxy
            manager.start()
        }
        .prefersStatusBarHidden()
        .backport
        .onChange(of: presentationCoordinator.isPresented) { _, isPresented in
            Container.shared.mediaPlayerManager.reset()
            guard !isPresented else { return }
            manager.stop()
        }
        .alert(
            L10n.error,
            isPresented: .constant(manager.error != nil)
        ) {
            Button(L10n.close, role: .cancel) {
                Container.shared.mediaPlayerManager.reset()
                router.dismiss()
            }
        } message: {
            Text(L10n.unableToLoadThisItem)
        }
        .onFinalDisappear {
            manager.stop()
        }
    }
}

extension NativeVideoPlayer {

    private struct NativeVideoPlayerView: UIViewControllerRepresentable {

        let proxy: AVMediaPlayerProxy
        let manager: MediaPlayerManager

        func makeUIViewController(context: Context) -> UINativeVideoPlayerViewController {
            UINativeVideoPlayerViewController(proxy: proxy, manager: manager)
        }

        func updateUIViewController(_ uiViewController: UINativeVideoPlayerViewController, context: Context) {}
    }

    private class UINativeVideoPlayerViewController: AVPlayerViewController, UIGestureRecognizerDelegate {

        private let proxy: AVMediaPlayerProxy
        private weak var manager: MediaPlayerManager?
        private var cancellables: Set<AnyCancellable> = []
        private var segmentCancellables: Set<AnyCancellable> = []

        init(proxy: AVMediaPlayerProxy, manager: MediaPlayerManager) {
            self.proxy = proxy
            self.manager = manager

            super.init(nibName: nil, bundle: nil)

            #if os(tvOS)
            observeSegments(of: manager)
            #endif

            player = proxy.player

            player?.allowsExternalPlayback = true
            player?.appliesMediaSelectionCriteriaAutomatically = false
            player?.usesExternalPlaybackWhileExternalScreenIsActive = true
            allowsPictureInPicturePlayback = true

            #if !os(tvOS)
            updatesNowPlayingInfoCenter = false
            #endif
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        #if !os(tvOS)
        override func viewDidLoad() {
            super.viewDidLoad()

            // Without insight into AVKit overlay presentation, restart
            // the standalone skip button window on the taps that toggle it.
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTap))
            tapRecognizer.cancelsTouchesInView = false
            tapRecognizer.delegate = self
            view.addGestureRecognizer(tapRecognizer)
        }

        @objc
        private func didReceiveTap() {
            manager?.segmentObserver?.refreshStandalonePresentation()
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
        #endif

        #if os(tvOS)
        /// Presents skippable segments as AVKit contextual actions,
        /// which are natively rendered, positioned, and focusable.
        private func observeSegments(of manager: MediaPlayerManager) {
            manager.$playbackItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self, weak manager] _ in
                    guard let self, let observer = manager?.segmentObserver else { return }
                    self.observeSegments(of: observer)
                }
                .store(in: &cancellables)
        }

        private func observeSegments(of observer: MediaSegmentObserver) {
            segmentCancellables = []

            observer.$currentSegment
                .combineLatest(observer.$isStandalonePresentation)
                .receive(on: DispatchQueue.main)
                .sink { [weak self, weak observer] segment, isStandalonePresentation in
                    guard let segment, let type = segment.type, isStandalonePresentation else {
                        self?.contextualActions = []
                        return
                    }

                    self?.contextualActions = [
                        UIAction(title: type.skipActionTitle) { _ in
                            observer?.skipCurrentSegment()
                        },
                    ]
                }
                .store(in: &segmentCancellables)
        }
        #endif
    }
}
