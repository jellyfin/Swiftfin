//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Observation
import SwiftUI

extension VideoPlayer {

    @MainActor
    @Observable
    final class ViewState {

        enum Presentation: Equatable {
            case hidden
            case progress
            case controls
            case supplement(String, showsPlaybackButtons: Bool = true)
        }

        enum Element {
            case progress
            case toolbar
            case playbackButtons
            case supplements
            case dimming
        }

        enum AspectFillBehavior {
            case fit
            case fill
        }

        enum Interaction: Hashable {
            case pan
            case speedBoost
            case button(UUID)
            case menu(UUID)
        }

        enum Focus {
            static let progress = "player.progress"
            static let controls = "player.controls"
            static let supplementBoundary = "player.supplementBoundary"
            static let supplementTabs = "player.supplementTabs"

            static func action(_ id: String) -> String {
                "player.action.\(id)"
            }

            static func supplementContent(_ id: String) -> String {
                "player.supplementContent.\(id)"
            }
        }

        private(set) var presentation: Presentation = .hidden

        private(set) var aspectFillBehavior: AspectFillBehavior = .fit

        var isGestureLocked: Bool = false {
            didSet {
                if isGestureLocked {
                    hideControls()
                }
            }
        }

        var isCompact: Bool = false

        var isScrubbing: Bool = false {
            didSet { refreshAutoDismiss() }
        }

        var selectedSupplementID: String? {
            get {
                guard case let .supplement(id, _) = presentation else { return nil }
                return id
            }
            set {
                guard !isGestureLocked, newValue != selectedSupplementID else { return }
                transition(to: newValue.map { .supplement($0) } ?? .controls)
            }
        }

        var selectedSupplement: (any MediaPlayerSupplement)? {
            guard let selectedSupplementID else { return nil }
            access(keyPath: \.selectedSupplement)
            return manager?.supplements.first { $0.id == selectedSupplementID }
        }

        var isPresentingSupplement: Bool {
            selectedSupplementID != nil
        }

        var isPresentingControls: Bool {
            presentation == .controls || isPresentingSupplement
        }

        var isPresentingProgress: Bool {
            visibleElements.contains(.progress)
        }

        var isProgressBarFocused: Bool {
            focusCoordinator.focusedIDs.contains(Focus.progress)
        }

        var isFocusOutsidePlayer: Bool {
            focusCoordinator.focusedIDs.isEmpty && focusCoordinator.lastFocusedIDs.isNotEmpty
        }

        var presentationControllerShouldDismiss: Bool {
            presentation == .controls && !isScrubbing && interactions.isEmpty
        }

        /// Layout and interaction affect visibility, without writing another state.
        var visibleElements: Set<Element> {
            guard !isGestureLocked else { return [] }
            if isScrubbing {
                return [.progress]
            }

            switch presentation {
            case .hidden:
                return []
            case .progress:
                return [.progress]
            case .controls:
                return [.progress, .toolbar, .playbackButtons, .supplements, .dimming]
            case let .supplement(_, showsPlaybackButtons):
                if UIDevice.isTV {
                    return [.supplements, .dimming]
                }

                if isCompact {
                    return showsPlaybackButtons
                        ? [.toolbar, .playbackButtons, .supplements, .dimming]
                        : [.toolbar, .supplements]
                }

                return selectedSupplement?.presentationStyle == .expanded
                    ? [.supplements, .dimming]
                    : [.toolbar, .supplements, .dimming]
            }
        }

        var originalPlaybackRate: Float?

        let centerOffsetBox: PublishedBox<CGFloat> = .init(initialValue: 0)
        let focusCoordinator: FocusCoordinator = .init()
        let jumpProgressObserver: JumpProgressObserver = .init()
        let scrubbedSeconds: PublishedBox<Duration> = .init(initialValue: .zero)
        let toastProxy: ToastProxy = .init()

        @ObservationIgnored
        weak var containerView: VideoPlayer.UIContainerViewController?
        @ObservationIgnored
        private(set) weak var manager: MediaPlayerManager?

        private let timer: PokeIntervalTimer
        private var interactions: Set<Interaction> = []
        @ObservationIgnored
        private var cancellables: Set<AnyCancellable> = []
        @ObservationIgnored
        private var playbackStatusCancellable: AnyCancellable?
        @ObservationIgnored
        private var playbackItemCancellable: AnyCancellable?
        @ObservationIgnored
        private var supplementsCancellable: AnyCancellable?

        #if os(iOS)
        var panHandlingAction: (any _PanHandlingAction)?
        var didSwipe: Bool = false
        var lastTapLocation: CGPoint?
        #endif

        #if os(tvOS)
        var isPresentingCloseConfirmation: Bool = false {
            didSet { refreshAutoDismiss() }
        }

        var scrubOriginSeconds: Duration?

        func commitScrub() {
            guard isScrubbing else { return }

            manager?.proxy?.setSeconds(scrubbedSeconds.value)
            manager?.setPlaybackRequestStatus(status: .playing)
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

        init(timer: PokeIntervalTimer? = nil) {
            self.timer = timer ?? .init(defaultInterval: UIDevice.isTV ? 10 : 5)

            self.timer.sink { [weak self] in
                guard let self, canAutoDismiss else { return }

                // UIKit presentations do not all participate in SwiftUI focus.
                if containerView?.presentedViewController != nil {
                    refreshAutoDismiss()
                    return
                }

                withAnimation(.linear(duration: 0.25)) {
                    self.hideControls()
                }
            }
            .store(in: &cancellables)

            focusCoordinator.$focusedIDs
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.refreshAutoDismiss()
                }
                .store(in: &cancellables)

            #if os(iOS)
            jumpProgressObserver.timer.sink { [weak self] in
                self?.lastTapLocation = nil
            }
            .store(in: &cancellables)
            #endif
        }

        func connect(manager: MediaPlayerManager) {
            withMutation(keyPath: \.selectedSupplement) {
                self.manager = manager
            }
            supplementsCancellable = manager.$supplements
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self, let selectedSupplementID else { return }

                    // Bridge the manager's Combine updates, including replacements with the same ID.
                    withMutation(keyPath: \.selectedSupplement) {
                        if self.manager?.supplements.contains(where: { $0.id == selectedSupplementID }) == true {
                            self.transition(to: self.presentation)
                        } else {
                            self.selectedSupplementID = nil
                        }
                    }
                }
            playbackItemCancellable = manager.$playbackItem
                .sink { [weak self] _ in
                    self?.fitVideo()
                }
            playbackStatusCancellable = manager.$playbackRequestStatus
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] status in
                    guard let self else { return }
                    #if os(tvOS)
                    if status == .paused, presentation == .hidden {
                        showControls()
                    }
                    #endif
                    refreshAutoDismiss()
                }
        }

        func fillVideo() {
            guard aspectFillBehavior != .fill else { return }
            aspectFillBehavior = .fill
        }

        func fitVideo() {
            guard aspectFillBehavior != .fit else { return }
            aspectFillBehavior = .fit
        }

        func toggleAspectFillBehavior() {
            aspectFillBehavior = aspectFillBehavior == .fit ? .fill : .fit
        }

        func showControls() {
            guard !isGestureLocked else { return }
            if !isPresentingControls {
                transition(to: .controls)
            } else {
                refreshAutoDismiss()
            }
        }

        /// Reveal the least UI needed for a seek, retaining an already open overlay.
        func showProgress(keepingControls: Bool = true) {
            guard !isGestureLocked else { return }
            if presentation == .hidden || !keepingControls {
                transition(to: .progress)
            } else {
                refreshAutoDismiss()
            }
        }

        func hideControls() {
            transition(to: .hidden)
        }

        func toggleControls() {
            if isPresentingControls {
                hideControls()
            } else {
                showControls()
            }
        }

        func togglePlaybackButtons() {
            guard isCompact, case let .supplement(id, showsPlaybackButtons) = presentation else { return }
            transition(to: .supplement(id, showsPlaybackButtons: !showsPlaybackButtons))
        }

        func setInteraction(_ interaction: Interaction, active: Bool) {
            if active {
                interactions.insert(interaction)
            } else {
                interactions.remove(interaction)
            }
            refreshAutoDismiss()
        }

        private var canAutoDismiss: Bool {
            guard presentation != .hidden,
                  !isScrubbing,
                  !isPresentingSupplement,
                  interactions.isEmpty,
                  manager?.playbackRequestStatus != .paused else { return false }

            #if os(tvOS)
            // Menus take focus out of the player, including nested system menus.
            // Resume the countdown only after focus returns to our controls.
            guard !isPresentingCloseConfirmation,
                  !isFocusOutsidePlayer
            else { return false }
            #endif

            return true
        }

        func refreshAutoDismiss() {
            if canAutoDismiss {
                timer.poke()
            } else {
                timer.stop()
            }
        }

        private func transition(to presentation: Presentation) {
            let wasPresentingSupplement = isPresentingSupplement
            let wasPresentingProgress = isPresentingProgress
            self.presentation = presentation

            if wasPresentingSupplement || isPresentingSupplement {
                containerView?.presentSupplementContainer(isPresentingSupplement)
            }

            #if os(tvOS)
            if isPresentingProgress, !wasPresentingProgress {
                focusCoordinator.focus(Focus.progress)
            }
            #endif

            refreshAutoDismiss()
        }
    }
}
