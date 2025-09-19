//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import SwiftUI

// TODO: turned into spaghetti to get out, clean up with a better state system
// TODO: verify timer states

@MainActor
class VideoPlayerContainerState: ObservableObject {

    @Published
    var isAspectFilled: Bool = false

    @Published
    var isGestureLocked: Bool = false {
        didSet {
            if isGestureLocked {
                isPresentingOverlay = false
            }
        }
    }

    // TODO: rename isPresentingPlaybackButtons
    @Published
    var isPresentingPlaybackControls: Bool = false

    // TODO: replace with graph dependency package
    func setPlaybackControlsVisibility() {

        guard isPresentingOverlay else {
            isPresentingPlaybackControls = false
            return
        }

        if isPresentingOverlay && !isPresentingSupplement {
            isPresentingPlaybackControls = true
            return
        }

        if isCompact {
            if isPresentingSupplement {
                if !isPresentingPlaybackControls {
                    isPresentingPlaybackControls = true
                }
            } else {
                isPresentingPlaybackControls = false
            }
        } else {
            isPresentingPlaybackControls = false
        }
    }

    @Published
    var isCompact: Bool = false {
        didSet {
            setPlaybackControlsVisibility()
        }
    }

    @Published
    var isGuestSupplement: Bool = false

    // TODO: rename isPresentingPlaybackControls
    @Published
    var isPresentingOverlay: Bool = false {
        didSet {
            setPlaybackControlsVisibility()

            if isPresentingOverlay, !isPresentingSupplement {
                timer.poke()
            }
        }
    }

    @Published
    private(set) var isPresentingSupplement: Bool = false {
        didSet {
            setPlaybackControlsVisibility()
            presentationControllerShouldDismiss = !isPresentingSupplement

            if isPresentingSupplement {
                timer.stop()
            } else {
                isGuestSupplement = false
                timer.poke()
            }
        }
    }

    @Published
    var isScrubbing: Bool = false {
        didSet {
            if isScrubbing {
                timer.stop()
            } else {
                timer.poke()
            }
        }
    }

    @Published
    var presentationControllerShouldDismiss: Bool = true

    @Published
    var selectedSupplement: (any MediaPlayerSupplement)? = nil {
        didSet {
            isPresentingSupplement = selectedSupplement != nil
        }
    }

    @Published
    var supplementOffset: CGFloat = 0.0

    @Published
    var centerOffset: CGFloat = 0.0

    let jumpProgressObserver: JumpProgressObserver = .init()
    let scrubbedSeconds: PublishedBox<Duration> = .init(initialValue: .zero)
    let timer: PokeIntervalTimer = .init()
    let toastProxy: ToastProxy = .init()

    weak var containerView: VideoPlayer.UIVideoPlayerContainerViewController?
    weak var manager: MediaPlayerManager?

    #if os(iOS)
    var panHandlingAction: (any _PanHandlingAction)?
    var didSwipe: Bool = false
    var lastTapLocation: CGPoint?
    #endif

    private var jumpProgressCancellable: AnyCancellable?
    private var timerCancellable: AnyCancellable?

    init() {
        timerCancellable = timer.sink { [weak self] in
            guard let self else { return }
            guard !isScrubbing, !isPresentingSupplement, manager?.playbackRequestStatus != .paused else { return }

            withAnimation(.linear(duration: 0.25)) {
                self.isPresentingOverlay = false
            }
        }

        #if os(iOS)
        jumpProgressCancellable = jumpProgressObserver
            .timer
            .sink { [weak self] in
                self?.lastTapLocation = nil
            }
        #endif
    }

    func select(supplement: (any MediaPlayerSupplement)?, isGuest: Bool = false) {
        isGuestSupplement = isGuest

        if supplement?.id == selectedSupplement?.id {
            selectedSupplement = nil
            containerView?.presentSupplementContainer(false)
        } else {
            selectedSupplement = supplement
            containerView?.presentSupplementContainer(supplement != nil)
        }
    }
}
