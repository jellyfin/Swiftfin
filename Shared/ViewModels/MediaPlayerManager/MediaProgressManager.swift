//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

class MediaProgressManager: MediaPlayerListener {

    func stateDidChange(newState: MediaPlayerManager.State) {}

    func secondsDidChange(newSeconds: TimeInterval) {}

    //    func sendStartReport() {
    //
    //        #if DEBUG
    //        guard Defaults[.sendProgressReports] else { return }
    //        #endif
    //
    //        currentProgressWorkItem?.cancel()
    //
    //        logger.debug("sent start report")
    //
    //        Task {
    //            let startInfo = PlaybackStartInfo(
    //                audioStreamIndex: audioTrackIndex,
    //                itemID: currentViewModel.item.id,
    //                mediaSourceID: currentViewModel.mediaSource.id,
    //                playbackStartTimeTicks: Int(Date().timeIntervalSince1970) * 10_000_000,
    //                positionTicks: currentProgressHandler.seconds * 10_000_000,
    //                sessionID: currentViewModel.playSessionID,
    //                subtitleStreamIndex: subtitleTrackIndex
    //            )
    //
    //            let request = Paths.reportPlaybackStart(startInfo)
    //            let _ = try await userSession.client.send(request)
    //
    //            let progressTask = DispatchWorkItem {
    //                self.sendProgressReport()
    //            }
    //
    //            currentProgressWorkItem = progressTask
    //
    //            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: progressTask)
    //        }
    //    }
    //
    //    func sendStopReport() {
    //
    //        let ids = ["itemID": currentViewModel.item.id, "seriesID": currentViewModel.item.parentID]
    //        Notifications[.itemMetadataDidChange].post(object: ids)
    //
    //        #if DEBUG
    //        guard Defaults[.sendProgressReports] else { return }
    //        #endif
    //
    //        logger.debug("sent stop report")
    //
    //        currentProgressWorkItem?.cancel()
    //
    //        Task {
    //            let stopInfo = PlaybackStopInfo(
    //                itemID: currentViewModel.item.id,
    //                mediaSourceID: currentViewModel.mediaSource.id,
    //                positionTicks: currentProgressHandler.seconds * 10_000_000,
    //                sessionID: currentViewModel.playSessionID
    //            )
    //
    //            let request = Paths.reportPlaybackStopped(stopInfo)
    //            let _ = try await userSession.client.send(request)
    //        }
    //    }
    //
    //    func sendPauseReport() {
    //
    //        #if DEBUG
    //        guard Defaults[.sendProgressReports] else { return }
    //        #endif
    //
    //        logger.debug("sent pause report")
    //
    //        currentProgressWorkItem?.cancel()
    //
    //        Task {
    //            let startInfo = PlaybackStartInfo(
    //                audioStreamIndex: audioTrackIndex,
    //                isPaused: true,
    //                itemID: currentViewModel.item.id,
    //                mediaSourceID: currentViewModel.mediaSource.id,
    //                positionTicks: currentProgressHandler.seconds * 10_000_000,
    //                sessionID: currentViewModel.playSessionID,
    //                subtitleStreamIndex: subtitleTrackIndex
    //            )
    //
    //            let request = Paths.reportPlaybackStart(startInfo)
    //            let _ = try await userSession.client.send(request)
    //        }
    //    }
    //
    //    func sendProgressReport() {
    //
    //        #if DEBUG
    //        guard Defaults[.sendProgressReports] else { return }
    //        #endif
    //
    //        let progressTask = DispatchWorkItem {
    //            self.sendProgressReport()
    //        }
    //
    //        currentProgressWorkItem = progressTask
    //
    //        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: progressTask)
    //
    //        Task {
    //            let progressInfo = PlaybackProgressInfo(
    //                audioStreamIndex: audioTrackIndex,
    //                isPaused: false,
    //                itemID: currentViewModel.item.id,
    //                mediaSourceID: currentViewModel.item.id,
    //                playSessionID: currentViewModel.playSessionID,
    //                positionTicks: currentProgressHandler.seconds * 10_000_000,
    //                sessionID: currentViewModel.playSessionID,
    //                subtitleStreamIndex: subtitleTrackIndex
    //            )
    //
    //            let request = Paths.reportPlaybackProgress(progressInfo)
    //            let _ = try await userSession.client.send(request)
    //
    //            logger.debug("sent progress task")
    //        }
    //    }
}
