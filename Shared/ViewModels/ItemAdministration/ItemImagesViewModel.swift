//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class ItemImagesViewModel: ViewModel, Stateful, Eventful {

    enum Event: Equatable {
        case updated
        case error(ErrorMessage)
    }

    enum Action: Equatable {
        case cancel
        case refresh
        case setImage(RemoteImageInfo)
        case uploadImage(image: UIImage, type: ImageType)
        case uploadFile(file: URL, type: ImageType)
        case deleteImage(ImageInfo)
    }

    enum BackgroundState: Hashable {
        case updating
    }

    enum State: Hashable {
        case initial
        case content
        case error(ErrorMessage)
    }

    // MARK: - Published Variables

    @Published
    var item: BaseItemDto
    @Published
    var images: [ImageType: [ImageInfo]] = [:]

    // MARK: - State Management

    @Published
    var state: State = .initial
    @Published
    var backgroundStates: Set<BackgroundState> = []

    private var task: AnyCancellable?
    private let eventSubject = PassthroughSubject<Event, Never>()

    // MARK: - Eventful

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Init

    init(item: BaseItemDto) {
        self.item = item
    }

    // MARK: - Respond to Actions

    func respond(to action: Action) -> State {
        switch action {

        case .cancel:
            task?.cancel()
            return .initial

        case .refresh:
            task?.cancel()

            task = Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.insert(.updating)
                        self.images.removeAll()
                    }

                    try await self.getAllImages()

                    await MainActor.run {
                        self.state = .content
                        _ = self.backgroundStates.remove(.updating)
                    }
                } catch {
                    let apiError = ErrorMessage(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                        self.backgroundStates.remove(.updating)
                    }
                }
            }.asAnyCancellable()

            return .initial

        case let .setImage(remoteImageInfo):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.insert(.updating)
                    }

                    try await self.setImage(remoteImageInfo)
                    try await self.getAllImages()

                    await MainActor.run {
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = ErrorMessage(error.localizedDescription)
                    await MainActor.run {
                        self.eventSubject.send(.error(apiError))
                    }
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.updating)
                }
            }.asAnyCancellable()

            return .content

        case let .uploadImage(image, type):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.insert(.updating)
                    }

                    try await self.uploadPhoto(image, type: type)
                    try await self.getAllImages()

                    await MainActor.run {
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = ErrorMessage(error.localizedDescription)
                    await MainActor.run {
                        self.eventSubject.send(.error(apiError))
                    }
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.updating)
                }
            }.asAnyCancellable()

            return .content

        case let .uploadFile(url, type):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.insert(.updating)
                    }

                    try await self.uploadFile(url, type: type)
                    try await self.getAllImages()

                    await MainActor.run {
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = ErrorMessage(error.localizedDescription)
                    await MainActor.run {
                        self.eventSubject.send(.error(apiError))
                    }
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.updating)
                }
            }.asAnyCancellable()

            return .content

        case let .deleteImage(imageInfo):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.insert(.updating)
                    }

                    try await deleteImage(imageInfo)
                    try await refreshItem()

                    await MainActor.run {
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = ErrorMessage(error.localizedDescription)
                    await MainActor.run {
                        self.eventSubject.send(.error(apiError))
                    }
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.updating)
                }
            }.asAnyCancellable()

            return .content
        }
    }

    // MARK: - Get All Item Images

    private func getAllImages() async throws {
        guard let itemID = item.id else { return }

        let request = Paths.getItemImageInfos(itemID: itemID)
        let response = try await self.userSession.client.send(request)

        let newImages: [ImageType: [ImageInfo]] = response.value.grouped(by: \.imageType)
            .mapValues { $0.sorted(using: \.imageIndex) }
            .reduce(into: [:]) { partialResult, kv in
                guard let k = kv.key else { return }
                partialResult[k] = kv.value
            }

        await MainActor.run {
            self.images = newImages
        }
    }

    // MARK: - Set Image From URL

    private func setImage(_ remoteImageInfo: RemoteImageInfo) async throws {
        guard let itemID = item.id,
              let type = remoteImageInfo.type,
              let imageURL = remoteImageInfo.url else { return }

        let parameters = Paths.DownloadRemoteImageParameters(type: type, imageURL: imageURL)
        let imageRequest = Paths.downloadRemoteImage(itemID: itemID, parameters: parameters)
        try await userSession.client.send(imageRequest)
    }

    // MARK: - Upload Image/File

    private func upload(imageData: Data, imageType: ImageType, contentType: String) async throws {
        guard let itemID = item.id else { return }

        let uploadLimit: Int = 30_000_000

        guard imageData.count <= uploadLimit else {
            throw ErrorMessage(
                "This image (\(imageData.count.formatted(.byteCount(style: .file)))) exceeds the maximum allowed size for upload (\(uploadLimit.formatted(.byteCount(style: .file)))."
            )
        }

        var request = Paths.setItemImage(
            itemID: itemID,
            imageType: imageType.rawValue,
            imageData.base64EncodedData()
        )
        request.headers = ["Content-Type": contentType]

        _ = try await userSession.client.send(request)
    }

    // MARK: - Prepare Photo for Upload

    private func uploadPhoto(_ image: UIImage, type: ImageType) async throws {
        let contentType: String
        let imageData: Data

        if let pngData = image.pngData() {
            contentType = "image/png"
            imageData = pngData
        } else if let jpgData = image.jpegData(compressionQuality: 1) {
            contentType = "image/jpeg"
            imageData = jpgData
        } else {
            logger.error("Unable to convert given profile image to png/jpg")
            throw ErrorMessage("An internal error occurred")
        }

        try await upload(
            imageData: imageData,
            imageType: type,
            contentType: contentType
        )
    }

    // MARK: - Prepare Image for Upload

    private func uploadFile(_ url: URL, type: ImageType) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            logger.error("Unable to access file at \(url)")
            throw ErrorMessage("An internal error occurred.")
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let contentType: String
        let imageData: Data

        switch url.pathExtension.lowercased() {
        case "png":
            contentType = "image/png"
            imageData = try Data(contentsOf: url)
        case "jpeg", "jpg":
            contentType = "image/jpeg"
            imageData = try Data(contentsOf: url)
        default:
            guard let image = try UIImage(data: Data(contentsOf: url)) else {
                logger.error("Unable to load image from file")
                throw ErrorMessage("An internal error occurred.")
            }

            if let pngData = image.pngData() {
                contentType = "image/png"
                imageData = pngData
            } else if let jpgData = image.jpegData(compressionQuality: 1) {
                contentType = "image/jpeg"
                imageData = jpgData
            } else {
                logger.error("Failed to convert image to png/jpg")
                throw ErrorMessage("An internal error occurred.")
            }
        }

        try await upload(
            imageData: imageData,
            imageType: type,
            contentType: contentType
        )
    }

    // MARK: - Delete Image

    private func deleteImage(_ imageInfo: ImageInfo) async throws {
        guard let itemID = item.id,
              let imageType = imageInfo.imageType else { return }

        if let imageIndex = imageInfo.imageIndex {
            let request = Paths.deleteItemImageByIndex(
                itemID: itemID,
                imageType: imageType.rawValue,
                imageIndex: imageIndex
            )

            try await userSession.client.send(request)
        } else {
            let request = Paths.deleteItemImage(
                itemID: itemID,
                imageType: imageType.rawValue
            )

            try await userSession.client.send(request)
        }

        try await getAllImages()
    }

    // MARK: - Refresh Item

    private func refreshItem() async throws {
        guard let itemID = item.id else { return }

        await MainActor.run {
            _ = backgroundStates.insert(.updating)
        }

        let request = Paths.getItem(
            itemID: itemID,
            userID: userSession.user.id
        )

        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value
            _ = backgroundStates.remove(.updating)
            Notifications[.itemMetadataDidChange].post(item)
        }
    }
}
