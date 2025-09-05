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

@MainActor
class VideoPlayerContainerState: ObservableObject {

    @Published
    var isAspectFilled: Bool = false

    @Published
    var isGestureLocked: Bool = false

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
    var selectedSupplement: AnyMediaPlayerSupplement? = nil {
        didSet {
            isPresentingSupplement = selectedSupplement != nil
        }
    }

    @Published
    var supplementOffset: CGFloat = 0.0

    @Published
    var centerOffset: CGFloat = 0.0

    var scrubbedSeconds: PublishedBox<Duration> = .init(initialValue: .zero)
    let timer = PokeIntervalTimer()

    private var timerCancellable: AnyCancellable?

    weak var containerView: UIVideoPlayerContainerViewController?

    init() {
        timerCancellable = timer.hasFired.sink { [weak self] in
            guard let self else { return }
            guard !isScrubbing == false, !isPresentingSupplement else { return }

            withAnimation(.linear(duration: 0.25)) {
                self.isPresentingOverlay = false
            }
        }
    }

    func select(supplement: AnyMediaPlayerSupplement?, isGuest: Bool = false) {
        isGuestSupplement = isGuest

        if supplement?.id == selectedSupplement?.id {
            selectedSupplement = nil
            containerView?.present(supplement: nil)
        } else {
            selectedSupplement = supplement
            containerView?.present(supplement: supplement)
        }
    }
}
