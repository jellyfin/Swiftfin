//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import AVFoundation
import Combine
import Defaults
import Foundation
import JellyfinAPI

@MainActor
@Observable
final class AirPlayVideoController: MediaSessionObserver {

    static let shared = AirPlayVideoController()

    enum Phase: Displayable {

        case inactive
        case preparing
        case active
        case restoring

        var displayTitle: String {
            switch self {
            case .inactive:
                L10n.onThisDevice
            case .preparing:
                L10n.preparingAirPlayVideo
            case .active:
                L10n.airPlayActive
            case .restoring:
                L10n.returningToThisDevice
            }
        }

        var isTransitioning: Bool {
            self == .preparing || self == .restoring
        }
    }

    private struct RoutePick {

        weak var player: any MediaPlayerExternalVideoProviding?
        let routeBeforePick: String?
    }

    private(set) var phase = Phase.inactive {
        didSet {
            if phase == .active {
                isAutomaticAirPlayBlocked = false
            }
            updateOutputPolicy()
        }
    }

    @ObservationIgnored
    private weak var mediaSession: MediaSession?
    @ObservationIgnored
    private var attemptPlayer: AVMediaPlayer?
    /// Set when an attempt fails and cleared when one succeeds, so a TV that cannot play the stream is not retried in a loop.
    @ObservationIgnored
    private var isAutomaticAirPlayBlocked = false
    @ObservationIgnored
    private var routePick: RoutePick?
    @ObservationIgnored
    private var routePickExpiry: AnyCancellable?
    @ObservationIgnored
    private var observations: Set<AnyCancellable> = []

    private init() {}

    var isAvailable: Bool {
        guard let mediaSession, !mediaSession.isRemotePlayback else { return false }

        return mediaSession.item.mediaType == .video && !mediaSession.item.isLiveStream
    }

    var isExternalVideoActive: Bool {
        (mediaSession?.player as? MediaPlayerExternalVideoProviding)?.isExternalVideoActive == true
    }

    func observe(_ mediaSession: MediaSession) -> AnyCancellable {
        guard Defaults[.Experimental.airPlayVideo] else { return AnyCancellable {} }

        self.mediaSession = mediaSession
        updateOutputPolicy()

        Notifications[.avAudioSessionRouteChange]
            .publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.routeDidChange()
            }
            .store(in: &observations)

        Task { [weak self, weak mediaSession] in
            let changes = ObservableValues { [weak mediaSession] in
                (
                    mediaSession?.player.map(ObjectIdentifier.init),
                    mediaSession?.state,
                    mediaSession?.item.id,
                    (mediaSession?.player as? MediaPlayerExternalVideoProviding)?.isExternalVideoActive
                )
            }

            for await _ in changes {
                guard !Task.isCancelled else { return }

                self?.sessionDidChange()
            }
        }
        .asAnyCancellable()
        .store(in: &observations)

        return AnyCancellable { [weak self] in
            self?.reset()
        }
    }

    private func reset() {
        observations.removeAll()
        routePick = nil
        routePickExpiry = nil
        attemptPlayer = nil
        isAutomaticAirPlayBlocked = false
        mediaSession = nil
        phase = .inactive
    }

    private func sessionDidChange() {
        guard let mediaSession else { return }

        if isExternalVideoActive {
            AirPlayVideoRoute.rememberCurrent()
        }

        if let attemptPlayer, mediaSession.player === attemptPlayer {
            attemptDidChange(attemptPlayer)
        } else if attemptPlayer != nil {
            if phase != .restoring {
                isAutomaticAirPlayBlocked = true
                phase = .restoring
            }
            if mediaSession.state == .playback || mediaSession.state == .error {
                finishAttempt()
            }
        } else {
            beginAttemptIfRouted()
        }

        updateOutputPolicy()
    }

    private func routeDidChange() {
        if phase == .active, AirPlayVideoRoute.currentID == nil {
            returnToLocal()
        }
        beginAttemptIfRouted()
    }

    private func beginAttemptIfRouted() {
        guard let mediaSession, attemptPlayer == nil, isAvailable else { return }

        let routeID = AirPlayVideoRoute.currentID
        let isNewPick = routePick != nil && routeID != nil && routeID != routePick?.routeBeforePick
        let isKnownTV = AirPlayVideoRoute.isCurrentRemembered && (routePick != nil || !isAutomaticAirPlayBlocked)

        guard isExternalVideoActive || isNewPick || isKnownTV else { return }

        let player = AVMediaPlayer(playbackProfile: .airPlayVideo)
        player.allowsExternalVideoPlayback = false
        guard mediaSession.transfer(to: player) != nil else { return }

        releaseRoutePick(restoringExternalPlayback: false)
        attemptPlayer = player
        phase = .preparing
    }

    func routePickerWillPresent() {
        guard isAvailable, attemptPlayer == nil, !isExternalVideoActive else { return }

        let player = mediaSession?.player as? MediaPlayerExternalVideoProviding
        routePickExpiry = nil
        routePick = RoutePick(player: player, routeBeforePick: AirPlayVideoRoute.currentID)
        player?.allowsExternalVideoPlayback = false
    }

    func routePickerDidEnd() {
        beginAttemptIfRouted()
        guard routePick != nil else { return }

        routePickExpiry = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(30)) } catch { return }
            guard let self else { return }

            releaseRoutePick(restoringExternalPlayback: true)
        }
        .asAnyCancellable()
    }

    private func releaseRoutePick(restoringExternalPlayback: Bool) {
        guard let pick = routePick else { return }

        routePick = nil
        routePickExpiry = nil
        if restoringExternalPlayback {
            pick.player?.allowsExternalVideoPlayback = !isAutomaticAirPlayBlocked
        }
    }

    private func attemptDidChange(_ player: AVMediaPlayer) {
        guard phase == .preparing, mediaSession?.state == .playback else { return }

        if AirPlayVideoRoute.currentID == nil {
            returnToLocal()
        } else {
            player.allowsExternalVideoPlayback = true
            phase = .active
        }
    }

    private func returnToLocal() {
        guard let mediaSession, phase != .restoring else { return }

        mediaSession.setPlaybackRequestStatus(status: .paused)
        phase = .restoring
        mediaSession.returnToLocalPlayback()
    }

    private func finishAttempt() {
        attemptPlayer = nil
        (mediaSession?.player as? MediaPlayerExternalVideoProviding)?.allowsExternalVideoPlayback = !isAutomaticAirPlayBlocked
        phase = .inactive
    }

    private func updateOutputPolicy() {
        guard let mediaSession else { return }

        let isExternal = attemptPlayer != nil || isExternalVideoActive
        var policy = MediaSession.OutputPolicy()
        policy.allowsTransfer = !isExternal
        policy.continuesInBackground = isExternalVideoActive || phase == .preparing
        policy.isChangingRoute = phase == .preparing
        policy.routeSharingPolicy = isAvailable ? .longFormVideo : .default

        if mediaSession.outputPolicy != policy {
            mediaSession.outputPolicy = policy
        }
    }
}
#endif
