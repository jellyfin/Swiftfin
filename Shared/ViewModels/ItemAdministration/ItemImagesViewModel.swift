//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import IdentifiedCollections
import JellyfinAPI
import OrderedCollections
import SwiftUI

class ItemImagesViewModel: ViewModel, Stateful, Eventful {

    enum Event: Equatable {
        case updated
        case deleted
        case error(JellyfinAPIError)
    }

    enum Action: Equatable {
        case cancel
        case refresh
        case setImage(RemoteImageInfo)
        case uploadPhoto(image: UIImage, type: ImageType)
        case uploadImage(file: URL, type: ImageType)
        case deleteImage(ImageInfo)
    }

    enum BackgroundState: Hashable {
        case refreshing
    }

    enum State: Hashable {
        case initial
        case content
        case updating
        case deleting
        case error(JellyfinAPIError)
    }

    // MARK: - Published Variables

    @Published
    var item: BaseItemDto
    @Published
    var images: IdentifiedArray<Int, ImageInfo> = []

    // MARK: - State Management

    @Published
    var state: State = .initial
    @Published
    var backgroundStates: OrderedSet<BackgroundState> = []

    private var task: AnyCancellable?
    private let eventSubject = PassthroughSubject<Event, Never>()

    // MARK: - Eventful

    var events: AnyPublisher<Event, Never> {
        eventSubject.receive(on: RunLoop.main).eraseToAnyPublisher()
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
            self.state = .initial

            return state

        case .refresh:
            task?.cancel()

            task = Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        self.state = .initial
                        _ = self.backgroundStates.append(.refreshing)
                        self.images.removeAll()
                    }

                    try await self.getAllImages()

                    await MainActor.run {
                        self.state = .content
                        _ = self.backgroundStates.remove(.refreshing)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                        self.backgroundStates.remove(.refreshing)
                    }
                }
            }.asAnyCancellable()

            return state

        case let .setImage(remoteImageInfo):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.state = .updating
                    }

                    try await self.setImage(remoteImageInfo)
                    try await self.getAllImages()

                    await MainActor.run {
                        self.state = .updating
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return state

        case let .uploadPhoto(image, type):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        self.state = .updating
                    }

                    try await self.uploadPhoto(image, type: type)
                    try await self.getAllImages()

                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return state

        case let .uploadImage(url, type):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        self.state = .updating
                    }

                    try await self.uploadImage(url, type: type)
                    try await self.getAllImages()

                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.updated)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return state

        case let .deleteImage(imageInfo):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        self.state = .deleting
                    }

                    try await deleteImage(imageInfo)
                    try await refreshItem()

                    await MainActor.run {
                        self.state = .deleting
                        self.eventSubject.send(.deleted)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.error(apiError))
                    }
                }
            }.asAnyCancellable()

            return state
        }
    }

    // MARK: - Get All Item Images

    private func getAllImages() async throws {
        guard let itemID = item.id else { return }

        let request = Paths.getItemImageInfos(itemID: itemID)
        let response = try await self.userSession.client.send(request)

        await MainActor.run {
            let updatedImages = response.value.sorted {
                if $0.imageType == $1.imageType {
                    return $0.imageIndex ?? 0 < $1.imageIndex ?? 0
                }
                return $0.imageType?.rawValue ?? "" < $1.imageType?.rawValue ?? ""
            }

            self.images = IdentifiedArray(uniqueElements: updatedImages)
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
            throw JellyfinAPIError(
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
            throw JellyfinAPIError("An internal error occurred")
        }

        try await upload(
            imageData: imageData,
            imageType: type,
            contentType: contentType
        )
    }

    // MARK: - Prepare Image for Upload

    private func uploadImage(_ url: URL, type: ImageType) async throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw JellyfinAPIError("Unable to access file at \(url)")
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
                throw JellyfinAPIError("Unable to load image from file")
            }

            if let pngData = image.pngData() {
                contentType = "image/png"
                imageData = pngData
            } else if let jpgData = image.jpegData(compressionQuality: 1) {
                contentType = "image/jpeg"
                imageData = jpgData
            } else {
                throw JellyfinAPIError("Failed to convert image to png/jpg")
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
              let imageType = imageInfo.imageType?.rawValue else { return }

        if let imageIndex = imageInfo.imageIndex {
            let request = Paths.deleteItemImageByIndex(
                itemID: itemID,
                imageType: imageType,
                imageIndex: imageIndex
            )

            try await userSession.client.send(request)
        } else {
            let request = Paths.deleteItemImage(
                itemID: itemID,
                imageType: imageType
            )

            try await userSession.client.send(request)
        }

        await MainActor.run {
            /// Remove the ImageInfo from local storage
            self.images.removeAll { $0 == imageInfo }

            /// Ensure that the remaining items have the correct new indexes
            if imageInfo.imageIndex != nil {
                self.images = IdentifiedArray(
                    uniqueElements: self.images.map { image in
                        var updatedImage = image
                        if updatedImage.imageType == imageInfo.imageType,
                           let imageIndex = updatedImage.imageIndex,
                           let targetIndex = imageInfo.imageIndex,
                           imageIndex > targetIndex
                        {
                            updatedImage.imageIndex = imageIndex - 1
                        }
                        return updatedImage
                    }
                )
            }
        }
    }

    // MARK: - Refresh Item

    private func refreshItem() async throws {
        guard let itemID = item.id else { return }

        await MainActor.run {
            _ = backgroundStates.append(.refreshing)
        }

        let request = Paths.getItem(
            userID: userSession.user.id,
            itemID: itemID
        )

        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value
            _ = backgroundStates.remove(.refreshing)
            Notifications[.itemMetadataDidChange].post(item)
        }
    }
}
