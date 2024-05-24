//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import Files
import Foundation
import Get
import JellyfinAPI

// TODO: Only move items if entire download successful
// TODO: Better state for which stage of downloading

class DownloadEntity: NSObject, ObservableObject {

    enum DownloadError: Error {

        case notEnoughStorage

        var localizedDescription: String {
            switch self {
            case .notEnoughStorage:
                return "Not enough storage"
            }
        }
    }

    enum State {

        case cancelled
        case complete
        case downloading(Double)
        case error(Error)
        case ready
    }

    @Injected(LogManager.service)
    private var logger
    @Injected(UserSession.current)
    private var userSession: UserSession!

    public var expectedSize: Int64 = -1

    @Published
    var state: State = .ready

    private var downloadTask: Task<Void, Never>?

    public var item: BaseItemDto
    public var localPlaybackInfo: PlaybackProgressInfo

    var imagesFolder: URL? {
        item.downloadFolder?.appendingPathComponent("Images")
    }

    var metadataFolder: URL? {
        item.downloadFolder?.appendingPathComponent("Metadata")
    }

    init(item: BaseItemDto) {
        self.item = item
        self.localPlaybackInfo = PlaybackProgressInfo(
            audioStreamIndex: 1,
            isPaused: false,
            itemID: self.item.id!,
            mediaSourceID: nil,
            positionTicks: 0,
            sessionID: nil,
            subtitleStreamIndex: 1
        )
    }

    func createFolder() throws {
        guard let downloadFolder = item.downloadFolder else { return }
        try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)
    }

    func download() {

        let task = Task {

            deleteRootFolder()

            // TODO: Look at TaskGroup for parallel calls
            do {
                try await downloadMedia()
            } catch {
                await MainActor.run {
                    self.state = .error(error)

                    Container.downloadManager()
                        .remove(task: self)
                }
                return
            }
            await downloadBackdropImage()
            await downloadPrimaryImage()

            saveMetadata()

            await MainActor.run {
                Container.downloadManager().markReady(task: self)
            }
        }

        self.downloadTask = task
    }

    func cancel() {
        self.downloadTask?.cancel()
        self.state = .cancelled

        logger.trace("Cancelled download for: \(item.displayTitle)")
    }

    func deleteRootFolder() {
        guard let downloadFolder = item.downloadFolder else { return }
        try? FileManager.default.removeItem(at: downloadFolder)
    }

    func encodeMetadata() -> Data {
        try! JSONEncoder().encode(item)
    }

    private func downloadMedia() async throws {

        guard let downloadFolder = item.downloadFolder else { return }

        let request = Paths.getDownload(itemID: item.id!)
        self.expectedSize = Int64(item.mediaSources!.first!.size!)

        let response = try await userSession.client.download(for: request, delegate: self)

        let subtype = response.response.mimeSubtype
        let mediaExtension = subtype == nil ? "" : ".\(subtype!)"

        do {
            try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)

            try FileManager.default.moveItem(
                at: response.value,
                to: downloadFolder.appendingPathComponent("Media\(mediaExtension)")
            )
        } catch {
            logger.error("Error downloading media for: \(item.displayTitle) with error: \(error.localizedDescription)")
        }
    }

    private func downloadBackdropImage() async {

        guard let type = item.type else { return }

        let imageURL: URL

        // TODO: move to BaseItemDto
        switch type {
        case .movie, .series:
            guard let url = item.imageSource(.backdrop, maxWidth: 600).url else { return }
            imageURL = url
        case .episode:
            guard let url = item.imageSource(.primary, maxWidth: 600).url else { return }
            imageURL = url
        default:
            return
        }

        guard let response = try? await userSession.client.download(
            for: .init(url: imageURL).withResponse(URL.self),
            delegate: self
        ) else { return }

        let filename = getImageFilename(from: response, secondary: "Backdrop")
        saveImage(from: response, filename: filename)
    }

    private func downloadPrimaryImage() async {

        guard let type = item.type else { return }

        let imageURL: URL

        switch type {
        case .movie, .series:
            guard let url = item.imageSource(.primary, maxWidth: 300).url else { return }
            imageURL = url
        default:
            return
        }

        guard let response = try? await userSession.client.download(
            for: .init(url: imageURL).withResponse(URL.self),
            delegate: self
        ) else { return }

        let filename = getImageFilename(from: response, secondary: "Primary")
        saveImage(from: response, filename: filename)
    }

    private func saveImage(from response: Response<URL>?, filename: String) {

        guard let response, let imagesFolder else { return }

        do {
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)

            try FileManager.default.moveItem(
                at: response.value,
                to: imagesFolder.appendingPathComponent(filename)
            )
        } catch {
            logger.error("Error saving image: \(error.localizedDescription)")
        }
    }

    private func getImageFilename(from response: Response<URL>, secondary: String) -> String {

        if let suggestedFilename = response.response.suggestedFilename {
            return suggestedFilename
        } else {
            let imageExtension = response.response.mimeSubtype ?? "png"
            return "\(secondary).\(imageExtension)"
        }
    }

    private func saveMetadata() {
        guard let metadataFolder else { return }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let itemJsonData = try! jsonEncoder.encode(item)
        let itemJson = String(data: itemJsonData, encoding: .utf8)
        let itemFileURL = metadataFolder.appendingPathComponent("Item.json")

        do {
            try FileManager.default.createDirectory(at: metadataFolder, withIntermediateDirectories: true)

            try itemJson?.write(to: itemFileURL, atomically: true, encoding: .utf8)
        } catch {
            logger.error("Error saving item metadata: \(error.localizedDescription)")
        }
    }

    func getImageURL(name: String) -> URL? {
        do {
            guard let imagesFolder else { return nil }
            let images = try FileManager.default.contentsOfDirectory(atPath: imagesFolder.path)

            guard let imageFilename = images.first(where: { $0.starts(with: name) }) else { return nil }

            return imagesFolder.appendingPathComponent(imageFilename)
        } catch {
            return nil
        }
    }

    func getMediaURL() -> URL? {
        do {
            guard let downloadFolder = item.downloadFolder else { return nil }
            let contents = try FileManager.default.contentsOfDirectory(atPath: downloadFolder.path)

            guard let mediaFilename = contents.first(where: { $0.starts(with: "Media") }) else { return nil }

            return downloadFolder.appendingPathComponent(mediaFilename)
        } catch {
            return nil
        }
    }
}

// MARK: URLSessionDownloadDelegate

extension DownloadEntity: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(expectedSize)

        DispatchQueue.main.async {
            self.state = .downloading(progress)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error else { return }

        DispatchQueue.main.async {
            self.state = .error(error)

            Container.downloadManager()
                .remove(task: self)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }

        DispatchQueue.main.async {
            self.state = .error(error)

            Container.downloadManager()
                .remove(task: self)
        }
    }
}

extension DownloadEntity: Identifiable {

    var id: String {
        item.id!
    }
}

extension DownloadEntity {
    func getPlaybackInfo() -> PlaybackProgressInfo {
        let itemProgressFile = URL.downloads
            .appendingPathComponent(self.id)
            .appendingPathComponent("Metadata")
            .appendingPathComponent("Progress.json")

        let jsonDecoder = JSONDecoder()
        guard let itemProgressData = FileManager.default.contents(atPath: itemProgressFile.path) else { return self.localPlaybackInfo }

        guard let offlineProgress = try? jsonDecoder.decode(PlaybackProgressInfo.self, from: itemProgressData)
        else { return self.localPlaybackInfo }

        return offlineProgress
    }

    func savePlaybackInfo(progress: PlaybackProgressInfo) {
        guard let metadataFolder = metadataFolder else { return }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let itemJsonData = try! jsonEncoder.encode(progress)
        let itemJson = String(data: itemJsonData, encoding: .utf8)
        let itemFileURL = metadataFolder.appendingPathComponent("Progress.json")

        do {
            try FileManager.default.createDirectory(at: metadataFolder, withIntermediateDirectories: true)

            try itemJson?.write(to: itemFileURL, atomically: true, encoding: .utf8)
        } catch {
            logger.error("Error saving item progress: \(error.localizedDescription)")
        }
    }

    func offlinePlayerViewModel() throws -> VideoPlayerViewModel {
        guard let playbackURL = self.getMediaURL() else { throw JellyfinAPIError("no media found") }
        let offlineProgress = self.getPlaybackInfo()

        return .init(
            playbackURL: playbackURL,
            item: self.item,
            mediaSource: .init(),
            playSessionID: offlineProgress.playSessionID ?? "",
            videoStreams: self.item.videoStreams,
            audioStreams: self.item.audioStreams,
            subtitleStreams: self.item.subtitleStreams,
            selectedAudioStreamIndex: self.localPlaybackInfo.audioStreamIndex ?? 1,
            selectedSubtitleStreamIndex: self.localPlaybackInfo.subtitleStreamIndex ?? -1,
            chapters: self.item.fullChapterInfo,
            streamType: .direct
        )
    }
}
