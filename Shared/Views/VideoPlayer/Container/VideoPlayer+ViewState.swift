//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import Observation
import SwiftUI

extension VideoPlayer {

    @MainActor
    @Observable
    final class ViewState {

        var layoutSize: CGSize = .zero
        var systemInsets: EdgeInsets = .zero

        var supplementInsets: EdgeInsets {
            #if os(tvOS)
            systemInsets.max(ViewLayout.platformDefault.edgePadding)
            #else
            EdgeInsets(top: 0, leading: systemInsets.leading, bottom: systemInsets.bottom, trailing: systemInsets.trailing)
            #endif
        }

        #if os(iOS)
        var supplementHeight: CGFloat = 0
        var supplementVisibleHeight: CGFloat = 0
        var playbackButtonsInsets: EdgeInsets = .zero
        #endif

        enum Presentation: Equatable {

            case hidden
            case progress
            case controls
            case supplement(String, showsPlaybackButtons: Bool = true)
        }

        enum Element {

            case overlayActions
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
            case pinch
            case speedBoost
            case button(UUID)
            case menu(UUID)
        }

        enum Focus {

            static let progress = "player.progress"
            static let controls = "player.controls"
            static let supplementTabs = "player.supplementTabs"

            static func action(_ id: String) -> String {
                "player.action.\(id)"
            }

            static func supplementContent(_ id: String) -> String {
                "player.supplementContent.\(id)"
            }
        }

        struct OverlayAction: Identifiable {

            struct ID: Hashable {

                let providerID: String
                let actionID: String

                var focusID: String {
                    "player.overlayAction.\(providerID.count):\(providerID)\(actionID)"
                }
            }

            let id: ID
            let button: VideoPlayerOverlayAction
        }

        var overlayActions: [OverlayAction] {
            let providers: [any VideoPlayerOverlayActionProviding] = (mediaSession?.playbackItem?
                .segments
                .map { [$0 as any VideoPlayerOverlayActionProviding] } ?? []) +
                supplements
                .compactMap { $0 as? any VideoPlayerOverlayActionProviding }

            return providers.flatMap { provider in
                provider.overlayActions.map {
                    OverlayAction(id: .init(providerID: provider.id, actionID: $0.id), button: $0)
                }
            }
        }

        var isPresentingOverlayActions: Bool {
            visibleElements.contains(.overlayActions)
        }

        var isOverlayActionFocused: Bool {
            isPresentingOverlayActions && overlayActions.contains { focusCoordinator.focusedIDs.contains($0.id.focusID) }
        }

        func performOverlayAction(_ id: OverlayAction.ID) {
            guard isPresentingOverlayActions,
                  let action = overlayActions.first(where: { $0.id == id })
            else { return }

            action.button.action()
            refreshAutoDismiss()
        }

        #if os(tvOS)
        private func focusPlaybackControls() {
            focusCoordinator.focus(mediaSession?.item.isLiveStream == true ? Focus.controls : Focus.progress)
        }

        func updateOverlayActionFocus(previousIDs: [OverlayAction.ID] = []) {
            guard !isPresentingCloseConfirmation,
                  containerView?.presentedViewController == nil
            else { return }

            if presentation == .hidden, isPresentingOverlayActions {
                if !isOverlayActionFocused, let first = overlayActions.first {
                    focusCoordinator.focus(first.id.focusID)
                }
            } else if isPresentingProgress,
                      previousIDs.contains(where: {
                          focusCoordinator.focusedIDs.contains($0.focusID) ||
                              focusCoordinator.lastFocusedIDs.contains($0.focusID)
                      }),
                      !isOverlayActionFocused
            {
                focusPlaybackControls()
            }
        }
        #endif

        private(set) var presentation: Presentation = .hidden

        private(set) var aspectFillBehavior: AspectFillBehavior = .fit

        var zoom = VideoZoom()

        var canPanZoom: Bool {
            !isGestureLocked && !isPresentingSupplement && zoom.canPan
        }

        func resetZoom() {
            if zoom.isPanning {
                setInteraction(.pan, active: false)
            }

            zoom.reset()
            setInteraction(.pinch, active: false)
        }

        var isGestureLocked: Bool = false {
            didSet {
                if isGestureLocked {
                    cancelScrub()
                    zoom.endInteraction()
                    setInteraction(.pan, active: false)
                    setInteraction(.pinch, active: false)
                    hideControls()
                }
            }
        }

        var isBeingDismissed = false
        var isCompact: Bool = false

        var isScrubbing: Bool {
            scrubPosition != nil
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

        var selectedSupplement: any VideoPlayerSupplement? {
            guard let selectedSupplementID else { return nil }

            return supplements.first { $0.id == selectedSupplementID }
        }

        private(set) var guestSupplement: any VideoPlayerSupplement?

        var supplements: [any VideoPlayerSupplement] {
            if let guestSupplement {
                return [guestSupplement]
            }

            guard let mediaSession, let item = mediaSession.playbackItem else { return [] }

            var selected = Defaults[.VideoPlayer.supplements].compactMap {
                $0.makeSupplement(for: item, queue: mediaSession.queue)
            }

            if item.baseItem.isLiveStream, Defaults[.Experimental.videoPlayerEPG] {
                selected.append(EPGSupplement())
            }

            return selected
        }

        var singleSupplement: any VideoPlayerSupplement? {
            let supplements = supplements

            return supplements.count == 1 ? supplements.first : nil
        }

        func presentGuestSupplement(_ supplement: some VideoPlayerSupplement) {
            guard !isGestureLocked else { return }

            guestSupplement = supplement
            transition(to: .supplement(supplement.id))
        }

        #if os(tvOS)
        private var pendingSupplementFocusID: String?

        var isSupplementFocusPending: Bool {
            pendingSupplementFocusID != nil
        }

        // The host fade and container slide can finish in either order. Keep the request
        // pending until the preferred control receives focus after these transitions.
        func focusSupplementIfNeeded(_ id: String) {
            guard pendingSupplementFocusID == id,
                  let selectedSupplement, selectedSupplement.id == id
            else { return }

            containerView?.focusSupplementContent()
            focusCoordinator.focus(selectedSupplement.preferredFocusID)
        }
        #endif

        var isPresentingSupplement: Bool {
            selectedSupplementID != nil
        }

        var isPresentingFullScreenSupplement: Bool {
            !isCompact && selectedSupplement?.presentationStyle == .expanded
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
                return overlayActions.isEmpty ? [] : [.overlayActions]

            case .progress:
                return overlayActions.isEmpty ? [.progress] : [.progress, .overlayActions]

            case .controls:
                var elements: Set<Element> = [.progress, .toolbar, .playbackButtons, .dimming]

                #if os(iOS)
                if overlayActions.isNotEmpty {
                    elements.insert(.overlayActions)
                }
                #endif

                if supplements.isNotEmpty {
                    elements.insert(.supplements)
                }

                return elements

            case let .supplement(_, showsPlaybackButtons):
                if ViewLayout.platformDefault.isLarge {
                    return [.supplements, .dimming]
                }

                if isCompact {
                    return showsPlaybackButtons
                        ? [.toolbar, .playbackButtons, .supplements, .dimming]
                        : [.toolbar, .supplements]
                }

                return isPresentingFullScreenSupplement
                    ? [.supplements, .dimming]
                    : [.toolbar, .supplements, .dimming]
            }
        }

        var originalPlaybackRate: Double?

        let focusCoordinator: FocusCoordinator = .init()
        let jumpProgressObserver: JumpProgressObserver = .init()

        private var scrubPosition: Duration? {
            didSet {
                if (oldValue == nil) != (scrubPosition == nil) {
                    refreshAutoDismiss()
                }
            }
        }

        var scrubbedSeconds: Duration {
            get {
                scrubPosition ?? mediaSession?.seconds ?? .zero
            }
            set {
                guard isScrubbing else { return }

                scrubPosition = newValue
            }
        }

        let toastProxy: ToastProxy = .init()

        @ObservationIgnored
        weak var containerView: VideoPlayer.UIContainerViewController?
        private(set) weak var mediaSession: MediaSession?

        private let timer: PokeIntervalTimer
        private var interactions: Set<Interaction> = []
        @ObservationIgnored
        private var cancellables: Set<AnyCancellable> = []
        @ObservationIgnored
        private var sessionObservations: Set<AnyCancellable> = []

        #if os(iOS)
        var panHandlingAction: any _PanHandlingAction?
        var didSwipe: Bool = false
        var lastTapLocation: CGPoint?

        func cancelTapGesture() {
            lastTapLocation = nil
            jumpProgressObserver.timer.stop()
            jumpProgressObserver.reset()
        }
        #endif

        #if os(tvOS)
        var isPresentingCloseConfirmation: Bool = false {
            didSet {
                refreshAutoDismiss()
            }
        }

        #endif

        private(set) var scrubOriginSeconds: Duration?

        func beginScrub() {
            guard !isScrubbing, !isGestureLocked, mediaSession?.canSeek == true else { return }

            scrubOriginSeconds = mediaSession?.seconds
            scrubPosition = scrubOriginSeconds
        }

        func commitScrub(resumePlayback: Bool = false) {
            guard isScrubbing else { return }

            mediaSession?.seek(to: scrubbedSeconds)

            if resumePlayback {
                mediaSession?.setPlaybackRequestStatus(status: .playing)
            }

            scrubPosition = nil
            scrubOriginSeconds = nil
        }

        func cancelScrub() {
            guard isScrubbing else { return }

            scrubPosition = nil
            scrubOriginSeconds = nil
        }

        init(timer: PokeIntervalTimer? = nil) {
            self.timer = timer ?? .init(defaultInterval: ViewLayout.platformDefault.isLarge ? 10 : 5)

            self.timer
                .sink { [weak self] in
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
                .sink { [weak self] focusedIDs in
                    guard let self else { return }

                    #if os(tvOS)
                    if let supplement = self.selectedSupplement,
                       self.pendingSupplementFocusID == supplement.id,
                       focusedIDs.contains(supplement.preferredFocusID)
                    {
                        self.pendingSupplementFocusID = nil
                    }
                    #endif

                    self.refreshAutoDismiss()
                }
                .store(in: &cancellables)

            #if os(iOS)
            jumpProgressObserver.timer
                .sink { [weak self] in
                    self?.lastTapLocation = nil
                }
                .store(in: &cancellables)
            #endif
        }

        isolated deinit {}

        func connect(mediaSession: MediaSession) {
            sessionObservations.removeAll()
            self.mediaSession = mediaSession
            var previousActivity: (MediaSession.Activity?, Bool)?

            let observations = [
                ObservationToken { [weak mediaSession] in
                    mediaSession?.playbackItem
                } onChange: { [weak self] _ in
                    guard let self else { return }

                    if let selectedSupplementID {
                        if supplements.contains(where: { $0.id == selectedSupplementID }) {
                            transition(to: presentation)
                        } else {
                            self.selectedSupplementID = nil
                        }
                    }

                    if supplements.isEmpty {
                        containerView?.cancelSupplementPan()
                    }

                    cancelScrub()

                    if let rate = originalPlaybackRate {
                        self.mediaSession?.rate = rate
                        originalPlaybackRate = nil
                    }

                    setInteraction(.speedBoost, active: false)

                    #if os(iOS)
                    cancelTapGesture()
                    panHandlingAction = nil
                    #endif

                    fitVideo()
                },
                ObservationToken { [weak mediaSession] in
                    mediaSession?.playbackRequestStatus
                } onChange: { [weak self] status in
                    guard let self else { return }

                    #if os(tvOS)
                    if status == .paused, presentation == .hidden {
                        showControls()
                    }
                    #endif

                    refreshAutoDismiss()
                },
                ObservationToken { [weak mediaSession] in
                    (mediaSession?.activity, mediaSession?.canSeek == true)
                } onChange: { [weak self] activity in
                    guard let self else { return }

                    if let previousActivity, previousActivity == activity {
                        return
                    }

                    previousActivity = activity

                    if !activity.1 {
                        cancelScrub()
                    }

                    refreshAutoDismiss()
                },
            ]

            observations.forEach { $0.store(in: &sessionObservations) }
        }

        func disconnect() {
            sessionObservations.removeAll()
            cancelScrub()
            timer.stop()

            #if os(iOS)
            cancelTapGesture()
            panHandlingAction = nil
            #endif

            mediaSession = nil
        }

        func fillVideo() {
            resetZoom()
            aspectFillBehavior = .fill
        }

        func fitVideo() {
            resetZoom()
            aspectFillBehavior = .fit
        }

        var isVideoEnlarged: Bool {
            zoom.transform.map { $0.scale > 1 } ?? (aspectFillBehavior == .fill)
        }

        func toggleAspectFillBehavior() {
            if isVideoEnlarged {
                fitVideo()
            } else {
                fillVideo()
            }
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
                  mediaSession?.activity == nil,
                  mediaSession?.playbackRequestStatus != .paused else { return false }

            #if os(tvOS)
            // Menus take focus out of the player, including nested system menus.
            // Resume the countdown only after focus returns to our controls.
            guard !isPresentingCloseConfirmation,
                  !isFocusOutsidePlayer
            else { return false }

            #endif

            return true
        }

        private var autoDismissInterval: TimeInterval {
            #if os(tvOS)
            // Short interval for progress only
            presentation == .progress ? 2 : 10
            #else
            5
            #endif
        }

        func refreshAutoDismiss() {
            if canAutoDismiss {
                timer.poke(interval: autoDismissInterval)
            } else {
                timer.stop()
            }
        }

        private func transition(to presentation: Presentation) {
            #if os(iOS)
            // A presentation change outside the tap handler ends the tap sequence.
            if self.presentation != presentation {
                lastTapLocation = nil
            }
            #endif

            if case .supplement = presentation {
                resetZoom()
            }

            let wasPresentingSupplement = isPresentingSupplement
            let wasPresentingProgress = isPresentingProgress
            let previousSupplementID = selectedSupplementID
            self.presentation = presentation

            if selectedSupplementID != guestSupplement?.id {
                guestSupplement = nil
            }

            #if os(tvOS)
            if selectedSupplementID != previousSupplementID {
                pendingSupplementFocusID = singleSupplement?.id == selectedSupplementID ? selectedSupplementID : nil
            }
            #endif

            if wasPresentingSupplement || isPresentingSupplement {
                containerView?.presentSupplementContainer(isPresentingSupplement)
            }

            #if os(tvOS)
            if isPresentingProgress, !wasPresentingProgress {
                focusPlaybackControls()
            }
            #endif

            refreshAutoDismiss()
        }
    }
}
