//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Files
import Foundation
import Get
import JellyfinAPI
import UIKit

// TODO: Only move items if entire download successful
// TODO: Better state for which stage of downloading

public class DownloadEntity: NSObject, ObservableObject {

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

    var seriesMetadataFolder: URL? {
        guard let seriesID = item.seriesID else { return nil }
        return URL.downloads.appendingPathComponent(seriesID).appendingPathComponent("Metadata")
    }

    var seriesImagesFolder: URL? {
        guard let seriesID = item.seriesID else { return nil }
        return URL.downloads.appendingPathComponent(seriesID).appendingPathComponent("Images")
    }

    var seasonMetadataFolder: URL? {
        guard let seasonID = item.seasonID else { return nil }
        return URL.downloads.appendingPathComponent(seasonID).appendingPathComponent("Metadata")
    }

    var seasonImagesFolder: URL? {
        guard let seasonID = item.seasonID else { return nil }
        return URL.downloads.appendingPathComponent(seasonID).appendingPathComponent("Images")
    }

    init(item: BaseItemDto) {
        self.item = item
        if item.mediaSources != nil {
            self.expectedSize = Int64(item.mediaSources!.first!.size!)
        }

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
            await downloadThumbImage()
            if item.type == .episode {
                await downloadSeriesData()
                await downloadSeasonMetadata()
            }

            do {
                try await loadFullItem()
            } catch {}
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
            guard let url = item.seriesImageSource(.backdrop, maxWidth: 600).url else { return }
            imageURL = url
        default:
            return
        }

        await downloadImage(url: imageURL, imageFolder: imagesFolder, name: "Backdrop")
    }

    private func downloadThumbImage() async {

        guard let type = item.type else { return }

        let imageURL: URL

        // TODO: move to BaseItemDto
        switch type {
        case .movie, .series:
            guard let url = item.imageSource(.thumb, maxWidth: 600).url else { return }
            imageURL = url
        case .episode:
            guard let url = item.seriesImageSource(.thumb, maxWidth: 600).url else { return }
            imageURL = url
        default:
            return
        }

        await downloadImage(url: imageURL, imageFolder: imagesFolder, name: "Thumb")
    }

    private func downloadSeriesData() async {
        guard let type = item.type else { return }
        if type != .episode {
            return
        }

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = ItemFields.allCases
        parameters.ids = [item.seriesID!]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)

        var item: BaseItemDto
        do {
            let response = try await userSession.client.send(request)
            guard let fullItem = response.value.items?.first else { throw JellyfinAPIError("Full item not in response") }
            item = fullItem
        } catch {
            logger.error("Error downloading series metadata for episode: \(error.localizedDescription)")
            return
        }

        guard let seriesMetadataFolder else { return }
        guard let seriesImagesFolder else { return }

        do {
            try FileManager.default.createDirectory(at: seriesMetadataFolder, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: seriesImagesFolder, withIntermediateDirectories: true)

            try saveItemFile(folder: seriesMetadataFolder, item: item)
        } catch {
            logger.error("Error saving series metadata: \(error.localizedDescription)")
        }

        guard let primary = item.imageSource(.primary, maxWidth: 600).url else { return }
        await downloadImage(url: primary, imageFolder: seriesImagesFolder, name: "Primary")
        guard let primary = item.imageSource(.backdrop, maxWidth: 600).url else { return }
        await downloadImage(url: primary, imageFolder: seriesImagesFolder, name: "Backdrop")
        guard let primary = item.imageSource(.thumb, maxWidth: 600).url else { return }
        await downloadImage(url: primary, imageFolder: seriesImagesFolder, name: "Thumb")
    }

    private func downloadSeasonMetadata() async {
        guard let type = item.type else { return }
        if type != .episode {
            return
        }

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = ItemFields.allCases
        parameters.ids = [item.seasonID!]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)

        var item: BaseItemDto
        do {
            let response = try await userSession.client.send(request)
            guard let fullItem = response.value.items?.first else { throw JellyfinAPIError("Full item not in response") }
            item = fullItem
        } catch {
            logger.error("Error downloading season metadata for episode: \(error.localizedDescription)")
            return
        }

        guard let seasonMetadataFolder else { return }
        guard let seasonImagesFolder else { return }

        do {
            try FileManager.default.createDirectory(at: seasonMetadataFolder, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: seasonImagesFolder, withIntermediateDirectories: true)

            try saveItemFile(folder: seasonMetadataFolder, item: item)
        } catch {
            logger.error("Error saving season metadata: \(error.localizedDescription)")
        }

        guard let primary = item.imageSource(.primary, maxWidth: 600).url else { return }
        await downloadImage(url: primary, imageFolder: seasonMetadataFolder, name: "Primary")
        guard let primary = item.imageSource(.backdrop, maxWidth: 600).url else { return }
        await downloadImage(url: primary, imageFolder: seasonMetadataFolder, name: "Backdrop")
        guard let primary = item.imageSource(.thumb, maxWidth: 600).url else { return }
        await downloadImage(url: primary, imageFolder: seasonMetadataFolder, name: "Thumb")
    }

    private func loadItemFile(folder: URL) -> BaseItemDto? {
        let itemFileURL = folder.appendingPathComponent("Item.json")
        guard let itemMetadataData = FileManager.default.contents(atPath: itemFileURL.path) else { return nil }
        let jsonDecoder = JSONDecoder()

        guard let offlineItem = try? jsonDecoder.decode(BaseItemDto.self, from: itemMetadataData) else { return nil }

        return offlineItem
    }

    private func saveItemFile(folder: URL, item: BaseItemDto) throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let itemJsonData = try jsonEncoder.encode(item)
        let itemJson = String(data: itemJsonData, encoding: .utf8)
        let itemFileURL = folder.appendingPathComponent("Item.json")

        try itemJson?.write(to: itemFileURL, atomically: true, encoding: .utf8)
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

        await downloadImage(url: imageURL, imageFolder: imagesFolder, name: "Primary")
    }

    private func downloadImage(url: URL, imageFolder: URL?, name: String) async {
        guard let response = try? await userSession.client.download(
            for: .init(url: url).withResponse(URL.self),
            delegate: self
        ) else { return }

        saveImage(from: response, folder: imageFolder, filename: name)
    }

    private func saveImage(from response: Response<URL>?, folder: URL?, filename: String) {

        guard let response, let folder else { return }

        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

            try FileManager.default.moveItem(
                at: response.value,
                to: folder.appendingPathComponent(filename)
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

    private func loadFullItem() async throws {
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = ItemFields.allCases
        parameters.ids = [item.id!]

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        guard let fullItem = response.value.items?.first else { throw JellyfinAPIError("Full item not in response") }
        item = fullItem
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

    func getImageURL(name: String, folder: URL?) -> URL? {
        do {
            guard let folder else { return nil }
            let images = try FileManager.default.contentsOfDirectory(atPath: folder.path)

            guard let imageFilename = images.first(where: { $0.starts(with: name) }) else { return nil }

            return folder.appendingPathComponent(imageFilename)
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

    public func urlSession(
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

    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error else { return }

        DispatchQueue.main.async {
            self.state = .error(error)

            Container.downloadManager()
                .remove(task: self)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }

        DispatchQueue.main.async {
            self.state = .error(error)

            Container.downloadManager()
                .remove(task: self)
        }
    }
}

extension DownloadEntity {
    var seriesItem: BaseItemDto? {
        guard let seriesMetadataFolder else { return nil }
        return loadItemFile(folder: seriesMetadataFolder)
    }

    var seasonItem: BaseItemDto? {
        guard let seasonMetadataFolder else { return nil }
        return loadItemFile(folder: seasonMetadataFolder)
    }

    func updatePlaybackInfo() {
        guard let metadataFolder = metadataFolder else { return }

        let itemProgressFile = metadataFolder.appendingPathComponent("Progress.json")

        let jsonDecoder = JSONDecoder()
        guard let itemProgressData = FileManager.default.contents(atPath: itemProgressFile.path) else { return }

        guard let offlineProgress = try? jsonDecoder.decode(PlaybackProgressInfo.self, from: itemProgressData)
        else { return }

        self.localPlaybackInfo = offlineProgress
        let position = self.localPlaybackInfo.positionTicks ?? 0
        self.item.userData?.playbackPositionTicks = position
        let runtime = self.item.runTimeTicks ?? 0
        self.item.userData?.playedPercentage = Double(position) / Double(runtime) * 100
    }

    func savePlaybackInfo(positionTicks: Int) {
        self.item.userData?.playbackPositionTicks = positionTicks
        let runtime = self.item.runTimeTicks ?? 0
        self.item.userData?.playedPercentage = Double(positionTicks) / Double(runtime) * 100
        saveMetadata()
    }

    func setIsPlayed(played: Bool) {
        self.item.userData?.isPlayed = played
        saveMetadata()
    }

    func offlinePlayerViewModel() throws -> VideoPlayerViewModel {
        guard let playbackURL = self.getMediaURL() else { throw JellyfinAPIError("no media found") }
        self.updatePlaybackInfo()

        return .init(
            playbackURL: playbackURL,
            item: self.item,
            mediaSource: .init(),
            playSessionID: self.localPlaybackInfo.playSessionID ?? "",
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

extension DownloadEntity: Displayable {
    var displayTitle: String {
        item.name ?? .emptyDash
    }
}

extension DownloadEntity: Poster {
    var subtitle: String? {
        switch item.type {
        case .episode:
            item.seasonEpisodeLabel
        case .video:
            item.extraType?.displayTitle
        default:
            nil
        }
    }

    var showTitle: Bool {
        switch item.type {
        case .episode, .series, .movie, .boxSet, .collectionFolder:
            Defaults[.Customization.showPosterLabels]
        default:
            true
        }
    }

    var systemImage: String {
        switch item.type {
        case .boxSet:
            "film.stack"
        case .channel, .tvChannel, .liveTvChannel, .program:
            "tv"
        case .episode, .movie, .series:
            "film"
        case .folder:
            "folder.fill"
        case .person:
            "person.fill"
        default:
            "circle"
        }
    }

    func portraitImageSources(maxWidth: CGFloat? = nil) -> [ImageSource] {
        switch item.type {
        case .episode:
            // TODO: offline series image source
            [ImageSource(url: self.getImageURL(name: "Primary", folder: seriesImagesFolder))]
        case .channel, .tvChannel, .liveTvChannel, .movie, .series:
            [ImageSource(url: self.getImageURL(name: "Primary", folder: imagesFolder))]
        default:
            []
        }
    }

    func landscapeImageSources(maxWidth: CGFloat? = nil) -> [ImageSource] {
        switch item.type {
        case .episode:
            if Defaults[.Customization.Episodes.useSeriesLandscapeBackdrop] {
                [
                    // TODO: offline series image source
                    ImageSource(url: self.getImageURL(name: "Thumb", folder: imagesFolder)),
                    ImageSource(url: self.getImageURL(name: "Backdrop", folder: imagesFolder)),
                    ImageSource(url: self.getImageURL(name: "Primary", folder: imagesFolder)),
                ]
            } else {
                [ImageSource(url: self.getImageURL(name: "Primary", folder: imagesFolder))]
            }
        case .folder, .program, .video:
            [ImageSource(url: self.getImageURL(name: "Primary", folder: imagesFolder))]
        default:
            [
                ImageSource(url: self.getImageURL(name: "Thumb", folder: imagesFolder)),
                ImageSource(url: self.getImageURL(name: "Backdrop", folder: imagesFolder)),
            ]
        }
    }

    func cinematicImageSources(maxWidth: CGFloat? = nil) -> [ImageSource] {
        switch item.type {
        case .episode:
            [ImageSource(url: self.getImageURL(name: "Backdrop", folder: imagesFolder))]
        default:
            [ImageSource(url: self.getImageURL(name: "Backdrop", folder: imagesFolder))]
        }
    }
}
