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
import JellyfinAPI
import UIKit

extension UserSessionManager {

    func observeSocketCommands() {
        $currentSession
            .map { session -> AnyPublisher<PlayRequest, Never> in
                session?.serverSocketManager.playCommands ?? Combine.Empty<PlayRequest, Never>().eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] command in
                Task { @MainActor in
                    self?.onReceive(playCommand: command)
                }
            }
            .store(in: &cancellables)

        $currentSession
            .map { session -> AnyPublisher<PlaystateRequest, Never> in
                session?.serverSocketManager.playstateCommands ?? Combine.Empty<PlaystateRequest, Never>().eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] command in
                Task { @MainActor in
                    self?.onReceive(playstateCommand: command)
                }
            }
            .store(in: &cancellables)

        $currentSession
            .map { session -> AnyPublisher<GeneralCommand, Never> in
                session?.serverSocketManager.generalCommands ?? Combine.Empty<GeneralCommand, Never>().eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] command in
                Task { @MainActor in
                    self?.onReceive(generalCommand: command)
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func onReceive(playCommand: PlayRequest) {
        guard let currentSession else { return }

        switch playCommand.playCommand {
        case .playNow, .none:
            let itemIDs = playCommand.itemIDs ?? []
            guard let itemID = itemIDs[safe: playCommand.startIndex ?? 0] ?? itemIDs.first else { return }

            playItem(
                id: itemID,
                mediaSourceID: playCommand.mediaSourceID,
                startPositionTicks: playCommand.startPositionTicks,
                userSession: currentSession
            )

        case .playNext:
            onReceive(playstateCommand: .init(command: .nextTrack, controllingUserID: playCommand.controllingUserID))

        case .playLast:
            onReceive(playstateCommand: .init(command: .previousTrack, controllingUserID: playCommand.controllingUserID))

        case .playInstantMix:
            // TODO: Implement instant mix
            return

        case .playShuffle:
            // TODO: Implement shuffle playback
            return
        }
    }

    @MainActor
    private func onReceive(playstateCommand: PlaystateRequest) {
        guard let mediaSession = mediaPlayerManager.currentSession else { return }

        switch playstateCommand.command {
        case .fastForward:
            mediaSession.seek(by: Defaults[.VideoPlayer.jumpForwardInterval].rawValue)

        case .nextTrack:
            guard let nextItem = mediaSession.queue?.nextItem else { return }

            mediaSession.playNewItem(intent: nextItem)

        case .pause:
            mediaSession.setPlaybackRequestStatus(status: .paused)

        case .playPause:
            mediaSession.togglePlayPause()

        case .previousTrack:
            guard let previousItem = mediaSession.queue?.previousItem else { return }

            mediaSession.playNewItem(intent: previousItem)

        case .rewind:
            mediaSession.seek(by: .zero - (Defaults[.VideoPlayer.jumpBackwardInterval].rawValue))

        case .seek:
            guard let ticks = playstateCommand.seekPositionTicks else { return }

            mediaSession.seek(to: .ticks(ticks))

        case .stop:
            mediaSession.stop()

        case .unpause:
            mediaSession.setPlaybackRequestStatus(status: .playing)

        case .none:
            return
        }
    }

    @MainActor
    private func onReceive(generalCommand: GeneralCommand) {
        guard let currentSession else { return }

        switch generalCommand.name {
        case .setAudioStreamIndex:
            guard let index = generalCommand.arguments?["Index"], let index = Int(index) else { return }

            mediaPlayerManager.currentSession?.playbackItem?.selectedAudioStreamIndex = index

        case .setMaxStreamingBitrate:
            guard let bitrate = generalCommand.arguments?["Bitrate"], let bitrate = Int(bitrate) else { return }

            mediaPlayerManager.currentSession?.setBitrate(bitrate: PlaybackBitrate(for: bitrate))

        case .setSubtitleStreamIndex:
            guard let index = generalCommand.arguments?["Index"], let index = Int(index) else { return }

            mediaPlayerManager.currentSession?.playbackItem?.selectedSubtitleStreamIndex = index

        case .displayContent:
            guard let itemID = generalCommand.arguments?["ItemId"] else { return }

            routePublisher.send(.item(id: itemID))

        case .playMediaSource:
            guard let itemID = generalCommand.arguments?["ItemId"] else { return }

            playItem(
                id: itemID,
                mediaSourceID: generalCommand.arguments?["MediaSourceId"],
                userSession: currentSession
            )

        case .playTrailers:
            guard let itemID = generalCommand.arguments?["ItemId"] else { return }

            playTrailers(itemID: itemID, userSession: currentSession)

        case .displayMessage:
            // TODO: Implement via Toast
            return

        case .setPlaybackOrder, .setRepeatMode, .setShuffleQueue:
            // TODO: Implement when queue shuffling exists
            return

        case .mute, .setVolume, .toggleMute, .unmute, .volumeDown, .volumeUp:
            // Ignore volume commands since this would be iOS only
            return

        default:
            // Ignore navigation commands
            return
        }
    }

    @MainActor
    private func playItem(
        id: String,
        mediaSourceID: String? = nil,
        startPositionTicks: Int? = nil,
        userSession: UserSession
    ) {
        Task { @MainActor in
            do {
                let entry = try await userSession.getFullItem(id: id)

                let mediaSource = entry.value?.mediaSources?.first {
                    $0.id == mediaSourceID
                }

                // Keep the record alive until the playback intent takes ownership
                guard var intent = withExtendedLifetime(entry, {
                    entry.snapshot.getPlaybackIntent(
                        userSession: userSession,
                        mediaSource: mediaSource
                    )
                }) else { return }

                if let startPositionTicks {
                    intent = intent.updating(startSeconds: .ticks(startPositionTicks))
                }

                // A command fetched for a previous login cannot start playback for the new user.
                guard currentSession === userSession else { return }

                let action = PlayMediaAction { [routePublisher] route in
                    routePublisher.send(route)
                }

                action(intent: intent)
            } catch {
                logger.error(
                    "Unable to play item from socket command",
                    metadata: ["error": .string(error.localizedDescription)]
                )
            }
        }
    }

    @MainActor
    private func playTrailers(itemID: String, userSession: UserSession) {
        Task { @MainActor in
            do {
                let request = Paths.getLocalTrailers(itemID: itemID, userID: userSession.user.id)
                let response = try await userSession.send(request)

                if let trailerID = response.value.first?.id {
                    playItem(id: trailerID, userSession: userSession)
                    return
                }

                let entry = try await userSession.getFullItem(id: itemID)
                guard let urlString = entry.value?.remoteTrailers?.first?.url else { return }

                #if os(tvOS)
                guard let externalURL = ExternalTrailerURL(string: urlString),
                      externalURL.canBeOpened
                else { return }

                await UIApplication.shared.open(externalURL.deepLink)
                #else
                guard let url = URL(string: urlString),
                      UIApplication.shared.canOpenURL(url)
                else { return }

                await UIApplication.shared.open(url)
                #endif
            } catch {
                logger.error(
                    "Unable to play trailers from socket command",
                    metadata: ["error": .string(error.localizedDescription)]
                )
            }
        }
    }
}
