//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI

// TODO: how to get seconds for current item

class MediaProgressListener: ViewModel, MediaPlayerListener {

    weak var manager: MediaPlayerManager? {
        didSet {
            if let manager = manager {
                setup(with: manager)
            }
        }
    }

    private var hasSentStart = false
    private var item: MediaPlayerItem?
    private var lastPlaybackStatus: MediaPlayerManager.PlaybackRequestStatus = .playing
    private var lastSeconds: TimeInterval = 0

    init(item: MediaPlayerItem) {
        self.item = item
        super.init()
    }

    private func sendReport() {
        guard let item else { return }

        switch lastPlaybackStatus {
        case .playing:
            if hasSentStart {
                sendProgressReport(for: item, seconds: lastSeconds)
            } else {
                sendStartReport(for: item, seconds: lastSeconds)
            }
        case .paused:
            sendProgressReport(for: item, seconds: lastSeconds, isPaused: true)
//        case .buffering: ()
        }
    }

    private func setup(with manager: MediaPlayerManager) {
        cancellables = []

//        Timer.publish(every: 5, on: .main, in: .common)
//            .autoconnect()
//            .sink { _ in
//                self.sendReport()
//            }
//            .store(in: &cancellables)

        manager.$playbackItem.sink(receiveValue: playbackItemDidChange).store(in: &cancellables)
//        manager.$seconds.sink(receiveValue: secondsDidChange).store(in: &cancellables)
        manager.$playbackRequestStatus.sink(receiveValue: playbackStatusDidChange).store(in: &cancellables)
    }

    private func playbackItemDidChange(newItem: MediaPlayerItem?) {

        if let item, newItem !== item {
            sendStopReport(for: item, seconds: lastSeconds)

            // release
            self.item = nil
        }
    }

    private func playbackStatusDidChange(newStatus: MediaPlayerManager.PlaybackRequestStatus) {
        lastPlaybackStatus = newStatus
    }

    private func secondsDidChange(newSeconds: TimeInterval) {
        lastSeconds = newSeconds
    }

    private func sendStartReport(for item: MediaPlayerItem, seconds: TimeInterval) {

        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }
        #endif

        Task {
            var info = PlaybackStartInfo()
            info.audioStreamIndex = item.selectedAudioStreamIndex
            info.itemID = item.baseItem.id
            info.mediaSourceID = item.mediaSource.id
            info.playSessionID = item.playSessionID
            info.positionTicks = Int(seconds * 10_000_000)
            info.sessionID = item.playSessionID
            info.subtitleStreamIndex = item.selectedSubtitleStreamIndex

            let request = Paths.reportPlaybackStart(info)
            let _ = try await userSession.client.send(request)

            self.hasSentStart = true
        }
        .asAnyCancellable()
        .store(in: &cancellables)
    }

    private func sendStopReport(for item: MediaPlayerItem, seconds: TimeInterval) {

        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }
        #endif

        Task {
            var info = PlaybackStopInfo()
            info.itemID = item.baseItem.id
            info.mediaSourceID = item.mediaSource.id
            info.positionTicks = Int(seconds * 10_000_000)
            info.sessionID = item.playSessionID

            let request = Paths.reportPlaybackStopped(info)
            let _ = try await userSession.client.send(request)
        }
        .asAnyCancellable()
        .store(in: &cancellables)
    }

    private func sendProgressReport(for item: MediaPlayerItem, seconds: TimeInterval, isPaused: Bool = false) {

        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }
        #endif

        Task {
            var info = PlaybackProgressInfo()
            info.audioStreamIndex = item.selectedAudioStreamIndex
            info.isPaused = isPaused
            info.itemID = item.baseItem.id
            info.mediaSourceID = item.mediaSource.id
            info.playSessionID = item.playSessionID
            info.positionTicks = Int(seconds * 10_000_000)
            info.sessionID = item.playSessionID
            info.subtitleStreamIndex = item.selectedSubtitleStreamIndex

            let request = Paths.reportPlaybackProgress(info)
            let _ = try await userSession.client.send(request)
        }
        .asAnyCancellable()
        .store(in: &cancellables)
    }
}
