//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class DownloadVideoPlayerManager: VideoPlayerManager {

    init(downloadTask: DownloadTask) {
        super.init()

        logger.info("Initializing DownloadVideoPlayerManager for item: \(downloadTask.item.displayTitle)")
        logger.info("Download task state: \(downloadTask.state)")

        guard let playbackURL = downloadTask.getMediaURL() else {
            logger.error("Download task does not have media url for item: \(downloadTask.item.displayTitle)")
            logger.error("Download folder: \(downloadTask.item.downloadFolder?.path ?? "nil")")

            // Try to list contents of download folder for debugging
            if let downloadFolder = downloadTask.item.downloadFolder {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: downloadFolder.path)
                    logger.error("Download folder contents: \(contents)")
                } catch {
                    logger.error("Error reading download folder: \(error)")
                }
            }

            // Create a fallback view model to prevent crashes
            self.createFallbackViewModel(for: downloadTask)
            return
        }

        logger.info("Found playback URL: \(playbackURL)")
        logger.info("File exists: \(FileManager.default.fileExists(atPath: playbackURL.path))")

        // Get streams from the downloaded item
        let videoStreams = downloadTask.item.videoStreams
        let audioStreams = downloadTask.item.audioStreams
        let subtitleStreams = downloadTask.item.subtitleStreams

        logger.info("Video streams: \(videoStreams.count)")
        logger.info("Audio streams: \(audioStreams.count)")
        logger.info("Subtitle streams: \(subtitleStreams.count)")

        // Use the first media source from the item if available, otherwise create empty one
        var mediaSource = downloadTask.item.mediaSources?.first ?? MediaSourceInfo()

        // Update the media source for local playback
        mediaSource.path = playbackURL.path
        mediaSource.isRemote = false
        mediaSource.isSupportsDirectPlay = true
        mediaSource.isSupportsDirectStream = true

        // Ensure media streams are populated
        if mediaSource.mediaStreams == nil || mediaSource.mediaStreams?.isEmpty == true {
            mediaSource.mediaStreams = videoStreams + audioStreams + subtitleStreams
        }

        logger.info("Creating VideoPlayerViewModel with URL: \(playbackURL)")

        self.currentViewModel = .init(
            playbackURL: playbackURL,
            item: downloadTask.item,
            mediaSource: mediaSource,
            playSessionID: "",
            videoStreams: videoStreams,
            audioStreams: audioStreams,
            subtitleStreams: subtitleStreams,
            selectedAudioStreamIndex: audioStreams.first?.index ?? 0,
            selectedSubtitleStreamIndex: subtitleStreams.first(where: { $0.isDefault ?? false })?.index ?? -1,
            chapters: downloadTask.item.fullChapterInfo,
            playMethod: .directPlay
        )

        logger.info("VideoPlayerViewModel created successfully")
    }

    private func createFallbackViewModel(for downloadTask: DownloadTask) {
        logger.warning("Creating fallback VideoPlayerViewModel due to missing media URL")

        // Create a minimal media source
        var mediaSource = MediaSourceInfo()
        mediaSource.id = downloadTask.item.id
        mediaSource.isRemote = false
        mediaSource.isSupportsDirectPlay = true
        mediaSource.isSupportsDirectStream = true

        // Create minimal streams with correct argument order: index, type
        let videoStream = MediaStream(
            codec: "h264",
            index: 0,
            type: .video
        )
        let audioStream = MediaStream(
            codec: "aac",
            index: 0,
            type: .audio
        )
        mediaSource.mediaStreams = [videoStream, audioStream]

        // Use the download folder path if available, otherwise use a safe fallback
        let fallbackURL: URL
        if let downloadFolder = downloadTask.item.downloadFolder {
            // Use a placeholder file in the actual download folder
            fallbackURL = downloadFolder.appendingPathComponent("placeholder.mp4")
            logger.warning("Using fallback URL in download folder: \(fallbackURL)")
        } else {
            // Last resort: use documents directory
            fallbackURL = URL.documents.appendingPathComponent("placeholder.mp4")
            logger.error("No download folder available, using documents fallback: \(fallbackURL)")
        }

        let viewModel = VideoPlayerViewModel(
            playbackURL: fallbackURL,
            item: downloadTask.item,
            mediaSource: mediaSource,
            playSessionID: "offline-fallback",
            videoStreams: [videoStream],
            audioStreams: [audioStream],
            subtitleStreams: [],
            selectedAudioStreamIndex: 0,
            selectedSubtitleStreamIndex: -1,
            chapters: downloadTask.item.fullChapterInfo,
            playMethod: .directPlay
        )
        self.currentViewModel = viewModel
    }

    override func getAdjacentEpisodes(for item: BaseItemDto) {}

    override func sendStartReport() {}

    override func sendPauseReport() {}

    override func sendStopReport() {}

    override func sendProgressReport() {}
}
