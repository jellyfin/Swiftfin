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
import Get
import JellyfinAPI
import Logging

@MainActor
final class MediaProgressReporter {

    private let userSession: UserSession
    private let reportQueue: MediaPlaybackReportQueue

    private var item: MediaPlayerItem?
    private let logger = Logger.swiftfin()
    weak var mediaSession: MediaSession?
    private var pendingProgressID: UUID?
    private let timer = PokeIntervalTimer()

    private var cancellables = Set<AnyCancellable>()

    init(userSession: UserSession, reportQueue: MediaPlaybackReportQueue) {
        self.userSession = userSession
        self.reportQueue = reportQueue
    }

    func start(_ item: MediaPlayerItem) {
        stop()

        self.item = item
        report(isStart: true)

        timer.sink { [weak self] in
            self?.report()
            self?.timer.poke()
        }
        .store(in: &cancellables)

        timer.poke()
    }

    func stop() {
        timer.stop()
        cancellables.removeAll()
        pendingProgressID = nil

        guard let item else { return }

        self.item = nil

        var info = PlaybackStopInfo()
        info.itemID = item.baseItem.id
        info.liveStreamID = item.mediaSource.liveStreamID
        info.mediaSourceID = item.mediaSource.id
        info.playSessionID = item.playSessionID
        info.positionTicks = mediaSession?.observedSeconds.ticks
        info.sessionID = item.playSessionID

        enqueue(Paths.reportPlaybackStopped(info))
    }

    private func report(isStart: Bool = false) {
        guard let item else { return }

        var info = PlaybackStateInfo()
        info.audioStreamIndex = item.selectedAudioStreamIndex
        info.isPaused = mediaSession?.playbackRequestStatus == .paused
        info.itemID = item.baseItem.id
        info.liveStreamID = item.mediaSource.liveStreamID
        info.mediaSourceID = item.mediaSource.id
        info.playSessionID = item.playSessionID
        info.positionTicks = mediaSession?.observedSeconds.ticks
        info.sessionID = item.playSessionID
        info.subtitleStreamIndex = item.selectedSubtitleStreamIndex ?? -1

        let report = PlaybackStateReport(info: info, secondarySubtitleStreamIndex: item.selectedSecondarySubtitleStreamIndex ?? -1)
        enqueue(report.request(isStart: isStart), isProgress: !isStart)
    }

    /// Releases an opened live stream when resolution is discarded before playback starts.
    static func discard(_ item: MediaPlayerItem, session: UserSession?) async {
        guard let liveStreamID = item.mediaSource.liveStreamID, let session else { return }

        let client = session.client

        await Task {
            _ = try? await client.send(Paths.closeLiveStream(liveStreamID: liveStreamID))
        }.value
    }

    private func enqueue(_ request: Get.Request<Void>, isProgress: Bool = false) {
        #if DEBUG
        guard Defaults[.sendProgressReports] else { return }

        #endif

        let progressID: UUID?

        if isProgress {
            guard pendingProgressID == nil else { return }

            progressID = UUID()
            pendingProgressID = progressID
        } else {
            progressID = nil
        }

        let client = userSession.client

        reportQueue.enqueue { [weak self, logger] in
            if let progressID {
                // Stopping or replacing playback invalidates queued progress reports.
                guard self?.pendingProgressID == progressID else { return }
            }

            defer {
                if let progressID, self?.pendingProgressID == progressID {
                    self?.pendingProgressID = nil
                }
            }

            do {
                _ = try await client.send(request)
            } catch {
                logger.warning("Unable to report playback: \(error.localizedDescription)")
            }
        }
    }
}

/// Adds the secondary subtitle index missing from the Swift SDK.
/// Servers that ignore this field can still use the primary index.
struct PlaybackStateReport: Encodable {

    let info: PlaybackStateInfo
    let secondarySubtitleStreamIndex: Int

    private enum CodingKeys: String, CodingKey {

        case secondarySubtitleStreamIndex = "SecondarySubtitleStreamIndex"
    }

    func encode(to encoder: Encoder) throws {
        try info.encode(to: encoder)

        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(secondarySubtitleStreamIndex, forKey: .secondarySubtitleStreamIndex)
    }

    func request(isStart: Bool) -> Get.Request<Void> {
        var request = isStart ? Paths.reportPlaybackStart(info) : Paths.reportPlaybackProgress(info)
        request.body = self

        return request
    }
}

/// Keeps stop/start reports ordered across sessions for the lifetime of the manager.
@MainActor
final class MediaPlaybackReportQueue {

    private var task: Task<Void, Never>?

    func enqueue(_ report: @escaping @MainActor () async -> Void) {
        let previous = task

        task = Task {
            await previous?.value
            await report()
        }
    }
}
