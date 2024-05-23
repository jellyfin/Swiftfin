//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

class DownloadVideoPlayerManager: VideoPlayerManager {

    private var task: DownloadTask? = nil
    init(downloadTask: DownloadTask) {
        super.init()
        guard let playbackURL = downloadTask.getMediaURL() else {
            logger.error("Download task does not have media url for item: \(downloadTask.item.displayTitle)")

            return
        }

        let itemProgressFile = URL.downloads
            .appendingPathComponent(downloadTask.id)
            .appendingPathComponent("Metadata")
            .appendingPathComponent("Progress.json")

        do {
            let jsonDecoder = JSONDecoder()
            let itemProgressData = FileManager.default.contents(atPath: itemProgressFile.path)!
            let offlineProgress = try jsonDecoder.decode(PlaybackProgressInfo.self, from: itemProgressData)
            downloadTask.localPlaybackInfo = offlineProgress
            downloadTask.item.userData?.playbackPositionTicks = downloadTask.localPlaybackInfo.positionTicks!
        } catch {}

        self.currentViewModel = .init(
            playbackURL: playbackURL,
            item: downloadTask.item,
            mediaSource: .init(),
            playSessionID: "",
            videoStreams: downloadTask.item.videoStreams,
            audioStreams: downloadTask.item.audioStreams,
            subtitleStreams: downloadTask.item.subtitleStreams,
            selectedAudioStreamIndex: downloadTask.localPlaybackInfo.audioStreamIndex!,
            selectedSubtitleStreamIndex: downloadTask.localPlaybackInfo.subtitleStreamIndex!,
            chapters: downloadTask.item.fullChapterInfo,
            streamType: .direct
        )
        self.task = downloadTask
    }

    override func getAdjacentEpisodes(for item: BaseItemDto) {}

    override func sendStartReport() {
        updateProgress()
    }

    override func sendPauseReport() {
        updateProgress()
    }

    override func sendStopReport() {
        updateProgress()
    }

    override func sendProgressReport() {
        updateProgress()
    }

    private func updateProgress() {
        Task {
            let progressInfo = PlaybackProgressInfo(
                audioStreamIndex: audioTrackIndex,
                isPaused: false,
                itemID: currentViewModel.item.id,
                mediaSourceID: currentViewModel.item.id,
                playSessionID: currentViewModel.playSessionID,
                positionTicks: currentProgressHandler.seconds * 10_000_000,
                sessionID: currentViewModel.playSessionID,
                subtitleStreamIndex: subtitleTrackIndex
            )

            guard let metadataFolder = task?.metadataFolder else { return }

            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted

            let itemJsonData = try! jsonEncoder.encode(progressInfo)
            let itemJson = String(data: itemJsonData, encoding: .utf8)
            let itemFileURL = metadataFolder.appendingPathComponent("Progress.json")

            do {
                try FileManager.default.createDirectory(at: metadataFolder, withIntermediateDirectories: true)

                try itemJson?.write(to: itemFileURL, atomically: true, encoding: .utf8)
            } catch {
                logger.error("Error saving item progress: \(error.localizedDescription)")
            }
        }
    }
}
