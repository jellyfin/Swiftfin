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

@MainActor
class VideoPlayerContainerState: ObservableObject {

    // MARK: - Batch Update Support

    private var isBatchingUpdates = false

    private func performBatchUpdate(_ block: () -> Void) {
        guard !isBatchingUpdates else {
            block()
            return
        }
        isBatchingUpdates = true
        objectWillChange.send()
        block()
        isBatchingUpdates = false
    }

    private func sendChangeIfNeeded() {
        if !isBatchingUpdates {
            objectWillChange.send()
        }
    }

    // MARK: - Published Properties

    var isAspectFilled: Bool = false {
        willSet { sendChangeIfNeeded() }
    }

    var isGestureLocked: Bool = false {
        willSet { sendChangeIfNeeded() }
        didSet {
            guard isGestureLocked != oldValue else { return }
            if isGestureLocked {
                performBatchUpdate {
                    isPresentingOverlay = false
                }
            }
        }
    }

    // TODO: rename isPresentingPlaybackButtons
    var isPresentingPlaybackControls: Bool = false {
        willSet { sendChangeIfNeeded() }
    }

    // TODO: replace with graph dependency package

    private func updatePlaybackControlsVisibility() {
        let newValue: Bool = if !isPresentingOverlay {
            false
        } else if !isPresentingSupplement {
            true
        } else if isCompact {
            true
        } else {
            false
        }

        if isPresentingPlaybackControls != newValue {
            isPresentingPlaybackControls = newValue
        }
    }

    var isCompact: Bool = false {
        willSet { sendChangeIfNeeded() }
        didSet {
            guard isCompact != oldValue else { return }
            performBatchUpdate {
                updatePlaybackControlsVisibility()
            }
        }
    }

    var isGuestSupplement: Bool = false {
        willSet { sendChangeIfNeeded() }
    }

    // TODO: rename isPresentingPlaybackControls
    var isPresentingOverlay: Bool = false {
        willSet { sendChangeIfNeeded() }
        didSet {
            guard isPresentingOverlay != oldValue else { return }
            performBatchUpdate {
                updatePlaybackControlsVisibility()
            }

            if isPresentingOverlay, !isPresentingSupplement {
                timer.poke()
            }
        }
    }

    private(set) var isPresentingSupplement: Bool = false {
        willSet { sendChangeIfNeeded() }
        didSet {
            guard isPresentingSupplement != oldValue else { return }
            performBatchUpdate {
                updatePlaybackControlsVisibility()
                presentationControllerShouldDismiss = !isPresentingSupplement
            }

            if isPresentingSupplement {
                timer.stop()
            } else {
                isGuestSupplement = false
                timer.poke()
            }
        }
    }

    var isScrubbing: Bool = false {
        willSet { sendChangeIfNeeded() }
        didSet {
            guard isScrubbing != oldValue else { return }
            if isScrubbing {
                timer.stop()
            } else {
                timer.poke()
            }
        }
    }

    var presentationControllerShouldDismiss: Bool = true {
        willSet { sendChangeIfNeeded() }
    }

    var selectedSupplement: (any MediaPlayerSupplement)? {
        willSet { sendChangeIfNeeded() }
        didSet {
            performBatchUpdate {
                isPresentingSupplement = selectedSupplement != nil
            }
        }
    }

    var supplementOffset: CGFloat = 0.0 {
        willSet { sendChangeIfNeeded() }
    }

    var centerOffset: CGFloat = 0.0 {
        willSet { sendChangeIfNeeded() }
    }

    var originalPlaybackRate: Float?

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

    #if os(tvOS)
    var isProgressBarFocused: Bool = false
    var hasEnteredScrubMode: Bool = false
    var scrubOriginSeconds: Duration?
    var isPresentingCloseConfirmation: Bool = false {
        willSet { sendChangeIfNeeded() }
    }

    func commitScrub() {
        guard hasEnteredScrubMode else { return }
        manager?.proxy?.setSeconds(scrubbedSeconds.value)
        isScrubbing = false
        hasEnteredScrubMode = false
        scrubOriginSeconds = nil
    }

    func cancelScrub() {
        guard hasEnteredScrubMode else { return }
        if let origin = scrubOriginSeconds {
            scrubbedSeconds.value = origin
        }
        isScrubbing = false
        hasEnteredScrubMode = false
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
        let isToggle = supplement?.id == selectedSupplement?.id

        performBatchUpdate {
            isGuestSupplement = isGuest

            if isToggle {
                selectedSupplement = nil
            } else {
                selectedSupplement = supplement
            }
        }

        containerView?.presentSupplementContainer(isToggle ? false : supplement != nil)
    }
}
