//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
        case refresh
        case backgroundRefresh
        case uploadImage(url: URL, type: ImageType)
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

    // MARK: - Image Variables

    private let includeAllLanguages: Bool

    // MARK: - Published Variables

    @Published
    var item: BaseItemDto
    @Published
    var images: [ImageInfo: UIImage] = [:]

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

    init(
        item: BaseItemDto,
        includeAllLanguages: Bool = false
    ) {
        self.item = item
        self.includeAllLanguages = includeAllLanguages
        super.init()

        Notifications[.itemMetadataDidChange]
            .publisher
            .sink { [weak self] item in
                guard let self else { return }
                self.item = item
                Task {
                    await MainActor.run {
                        self.send(.backgroundRefresh)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Respond to Actions

    func respond(to action: Action) -> State {
        switch action {

        case .backgroundRefresh:
            task?.cancel()

            task = Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.append(.refreshing)
                    }

                    try await self.getAllImages()

                    await MainActor.run {
                        _ = self.backgroundStates.remove(.refreshing)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.eventSubject.send(.error(apiError))
                        _ = self.backgroundStates.remove(.refreshing)
                    }
                }
            }.asAnyCancellable()

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
                        _ = self.backgroundStates.remove(.refreshing)
                    }
                }
            }.asAnyCancellable()

            return state

        case let .uploadImage(url, imageType):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.state = .updating
                    }

                    try await self.uploadImage(url, type: imageType)

                    await MainActor.run {
                        self.eventSubject.send(.updated)
                        _ = self.state = .updating
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.eventSubject.send(.error(apiError))
                        _ = self.state = .updating
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
                        _ = self.state = .deleting
                    }

                    try await self.deleteImage(imageInfo)

                    await MainActor.run {
                        self.eventSubject.send(.deleted)
                        _ = self.state = .deleting
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.eventSubject.send(.error(apiError))
                        _ = self.state = .deleting
                    }
                }
            }.asAnyCancellable()

            return state
        }
    }

    // MARK: - Get All Item Images

    private func getAllImages() async throws {
        guard let itemID = item.id else { return }

        // Get all of the ImageInfos for the Item
        let imageRequest = Paths.getItemImageInfos(itemID: itemID)
        let imageResponse = try await self.userSession.client.send(imageRequest)
        let imageInfos = imageResponse.value

        // Get Current vs New ImageInfos for comparison
        let currentImageInfos = Set(self.images.keys)
        let newImageInfos = Set(imageInfos)

        // Exit if all ImageInfos are the same
        guard currentImageInfos != newImageInfos else { return }

        // Remove missing ImageInfos from published Images
        await MainActor.run {
            self.images = self.images.filter { newImageInfos.contains($0.key) }
        }

        // Identify missing ImageInfos in the published Images
        let missingImageInfos = imageInfos.filter { !self.images.keys.contains($0) }

        // Get all UIImages for all missing ImageInfos
        try await withThrowingTaskGroup(of: (ImageInfo, UIImage).self) { group in
            for imageInfo in missingImageInfos {
                group.addTask {
                    do {
                        let parameters = Paths.GetItemImageParameters(
                            tag: imageInfo.imageTag ?? "",
                            imageIndex: imageInfo.imageIndex
                        )
                        let request = Paths.getItemImage(
                            itemID: itemID,
                            imageType: imageInfo.imageType?.rawValue ?? "",
                            parameters: parameters
                        )
                        let response = try await self.userSession.client.send(request)

                        // Convert the Response Data into a UIImage
                        if let image = UIImage(data: response.value) {
                            return (imageInfo, image)
                        }
                    } catch {
                        throw JellyfinAPIError("Failed to fetch image for \(imageInfo): \(error)")
                    }
                    throw JellyfinAPIError("Failed to fetch image for \(imageInfo)")
                }
            }

            // Publish ImageInfos
            for try await (imageInfo, image) in group {
                await MainActor.run {
                    self.images[imageInfo] = image
                }
            }
        }
    }

    // MARK: - Upload Image

    // TODO: Make actually work. 500 error. Bad format.
    private func uploadImage(_ url: URL, type: ImageType) async throws {
        guard let itemID = item.id else { return }

        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw JellyfinAPIError("Unable to access file at \(url)")
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try Data(contentsOf: url)
        let image = UIImage(data: data)!
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

        var request = Paths.setItemImage(
            itemID: itemID,
            imageType: type.rawValue,
            imageData
        )
        request.headers = ["Content-Type": contentType]

        _ = try await userSession.client.send(request)

        try await refreshItem()
    }

    // MARK: - Delete Image

    private func deleteImage(_ imageInfo: ImageInfo) async throws {
        guard let itemID = item.id,
              let imageType = imageInfo.imageType?.rawValue,
              let imageIndex = imageInfo.imageIndex else { return }

        let request = Paths.deleteItemImageByIndex(
            itemID: itemID,
            imageType: imageType,
            imageIndex: imageIndex
        )

        _ = try await userSession.client.send(request)

        try await refreshItem()

        await MainActor.run {
            self.images.removeValue(forKey: imageInfo)

            let updatedImages = self.images
                .sorted { lhs, rhs in
                    guard let lhsType = lhs.key.imageType, let rhsType = rhs.key.imageType else {
                        return false
                    }
                    if lhsType != rhsType {
                        return lhsType.rawValue < rhsType.rawValue
                    }
                    return (lhs.key.imageIndex ?? 0) < (rhs.key.imageIndex ?? 0)
                }
                .reduce(into: [ImageInfo: UIImage]()) { result, pair in
                    var updatedInfo = pair.key
                    if updatedInfo.imageType == imageInfo.imageType,
                       let index = updatedInfo.imageIndex,
                       index > imageInfo.imageIndex!
                    {
                        updatedInfo.imageIndex = index - 1
                    }
                    result[updatedInfo] = pair.value
                }

            self.images = updatedImages
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
