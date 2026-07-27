//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import FactoryKit
import Foundation
import JellyfinAPI

extension MediaPlayerManager {

    func observeSocketCommands() {
        let currentSession = Container.shared.userSessionManager().$currentSession

        currentSession
            .map { session -> AnyPublisher<PlaystateRequest, Never> in
                session?.serverSocketManager.playstateCommands ?? Combine.Empty<PlaystateRequest, Never>().eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] in self?.onReceive(playstateCommand: $0) }
            .store(in: &cancellables)

        currentSession
            .map { session -> AnyPublisher<GeneralCommand, Never> in
                session?.serverSocketManager.generalCommands ?? Combine.Empty<GeneralCommand, Never>().eraseToAnyPublisher()
            }
            .switchToLatest()
            .sink { [weak self] in self?.onReceive(generalCommand: $0) }
            .store(in: &cancellables)
    }

    private func onReceive(playstateCommand: PlaystateRequest) {
        switch playstateCommand.command {
        case .fastForward:
            proxy?.jumpForward(Defaults[.VideoPlayer.jumpForwardInterval].rawValue)
        case .nextTrack:
            guard let nextItem = queue?.nextItem else { return }
            playNewItem(provider: nextItem)
        case .pause:
            setPlaybackRequestStatus(status: .paused)
        case .playPause:
            togglePlayPause()
        case .previousTrack:
            guard let previousItem = queue?.previousItem else { return }
            playNewItem(provider: previousItem)
        case .rewind:
            proxy?.jumpBackward(Defaults[.VideoPlayer.jumpBackwardInterval].rawValue)
        case .seek:
            guard let ticks = playstateCommand.seekPositionTicks else { return }
            proxy?.setSeconds(.ticks(ticks))
        case .stop:
            stop()
        case .unpause:
            setPlaybackRequestStatus(status: .playing)
        case .none:
            return
        }
    }

    private func onReceive(generalCommand: GeneralCommand) {
        switch generalCommand.name {
        case .setAudioStreamIndex:
            guard let index = generalCommand.arguments?["Index"], let index = Int(index) else { return }
            playbackItem?.selectedAudioStreamIndex = index
        case .setMaxStreamingBitrate:
            guard let bitrate = generalCommand.arguments?["Bitrate"], let bitrate = Int(bitrate) else { return }
            setBitrate(bitrate: PlaybackBitrate(for: bitrate))
        case .setSubtitleStreamIndex:
            guard let index = generalCommand.arguments?["Index"], let index = Int(index) else { return }
            playbackItem?.selectedSubtitleStreamIndex = index
        default:
            return
        }
    }
}
