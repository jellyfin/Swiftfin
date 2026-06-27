//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import SwiftUI

// TODO: turned into spaghetti to get out, clean up with a better state system
// TODO: verify timer states
// TODO: for tvOS, some kind of focus token system
//       - help with Menu
//       - may help with alternate overlays

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
            presentationControllerShouldDismiss = isPresentingOverlay && !isPresentingSupplement

            if isPresentingOverlay, !isPresentingSupplement {
                timer.poke()
            }
        }
    }

    @Published
    private(set) var isPresentingSupplement: Bool = false {
        didSet {
            setPlaybackControlsVisibility()
            presentationControllerShouldDismiss = isPresentingOverlay && !isPresentingSupplement

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
    var presentationControllerShouldDismiss: Bool = false

    @Published
    var selectedSupplement: (any MediaPlayerSupplement)? = nil {
        didSet {
            isPresentingSupplement = selectedSupplement != nil
        }
    }

    @Published
    var isProgressBarFocused: Bool = false

    var originalPlaybackRate: Float?

    let centerOffsetBox: PublishedBox<CGFloat> = .init(initialValue: 0)
    let jumpProgressObserver: JumpProgressObserver = .init()
    let scrubbedSeconds: PublishedBox<Duration> = .init(initialValue: .zero)
    let timer: PokeIntervalTimer = .init(defaultInterval: UIDevice.isTV ? 10 : 5)
    let toastProxy: ToastProxy = .init()

    weak var containerView: VideoPlayer.UIVideoPlayerContainerViewController?
    weak var manager: MediaPlayerManager?

    #if os(iOS)
    var panHandlingAction: (any _PanHandlingAction)?
    var didSwipe: Bool = false
    var lastTapLocation: CGPoint?
    #endif

    #if os(tvOS)
    @Published
    var isPresentingCloseConfirmation: Bool = false

    var scrubOriginSeconds: Duration?

    /// Optional hook invoked when a scrub is committed, AFTER the local seek but BEFORE the default resume.
    /// Returns `true` if the seek was handled externally (e.g. SyncPlay coordinating it across a Watch
    /// Together group), in which case `commitScrub` skips its own `.playing`. Set by the tvOS player while
    /// in a group; unset (and thus a no-op) otherwise.
    var onSeekCommit: ((Duration) -> Bool)?

    /// Optional hook invoked when the USER toggles play/pause from the transport, with the desired playing
    /// state. Returns `true` if handled externally (SyncPlay coordinates it across the group), in which case
    /// the caller skips its own `setPlaybackRequestStatus`. Capturing the explicit press here — instead of
    /// inferring intent from the player's published status, which also flips for buffering / applied commands
    /// — is what keeps Watch Together play/pause reliable. Unset (no-op) outside a group / on iOS.
    var onUserPlayPauseIntent: ((Bool) -> Bool)?

    func commitScrub() {
        guard isScrubbing else { return }

        manager?.proxy?.setSeconds(scrubbedSeconds.value)
        // When something external handles the seek (SyncPlay coordinates it across the Watch Together group),
        // skip the default local resume — SyncPlay holds us paused and resumes everyone together on the
        // server's coordinated command. Outside a group the hook is unset and we resume immediately as usual.
        let handledExternally = onSeekCommit?(scrubbedSeconds.value) ?? false
        if !handledExternally {
            manager?.setPlaybackRequestStatus(status: .playing)
        }
        isScrubbing = false
        scrubOriginSeconds = nil
    }

    func cancelScrub() {
        guard isScrubbing else { return }

        if let manager {
            scrubbedSeconds.value = manager.seconds
        }

        isScrubbing = false
        scrubOriginSeconds = nil
    }
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
