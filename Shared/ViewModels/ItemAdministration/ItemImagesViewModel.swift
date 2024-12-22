//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Get
import IdentifiedCollections
import JellyfinAPI
import OrderedCollections
import UIKit
import URLQueryEncoder

private let DefaultPageSize = 50

class ItemImagesViewModel: ViewModel, Stateful, Eventful {

    enum Event: Equatable {
        case updated
        case error(JellyfinAPIError)
    }

    enum Action: Equatable {
        case cancel
        case refresh
        case setImageType(ImageType?)
        case getImages
        case getNextPage
        case setImage(url: String, index: Int = 0)
        case uploadImage(image: UIImage, index: Int = 0)
        case deleteImage(index: Int = 0)
    }

    enum BackgroundState: Hashable {
        case gettingNextPage
        case refreshing
    }

    enum State: Hashable {
        case initial
        case content
        case updating
        case error(JellyfinAPIError)
    }

    // MARK: - Published Variables

    @Published
    var item: BaseItemDto
    @Published
    var includeAllLanguages: Bool
    @Published
    var localImages: [String: [UIImage]] = [:]
    @Published
    var remoteImages: IdentifiedArrayOf<RemoteImageInfo> = []
    @Published
    var imageType: ImageType?

    // MARK: - Page Management

    private let pageSize: Int
    private(set) var currentPage: Int = 0
    private(set) var hasNextPage: Bool = true

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
        includeAllLanguages: Bool = false,
        pageSize: Int = DefaultPageSize
    ) {
        self.item = item
        self.includeAllLanguages = includeAllLanguages
        self.pageSize = pageSize
        super.init()
    }

    // MARK: - Respond to Actions

    func respond(to action: Action) -> State {
        switch action {

        case .cancel:
            task?.cancel()
            self.state = .initial

            return state

        case let .setImageType(type):
            self.imageType = type
            return state

        case .getImages:
            guard let imageType = imageType else {
                logger.error("Image type not set")
                return .error(JellyfinAPIError("Image type not set"))
            }

            task?.cancel()

            task = Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        self.state = .initial
                        self.localImages.removeAll()
                        self.currentPage = 0
                        self.hasNextPage = true
                        _ = self.backgroundStates.append(.refreshing)
                    }

                    try await self.getNextPage(imageType)

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

        case .getNextPage:
            guard let imageType else {
                logger.error("Image type not set")
                return .error(JellyfinAPIError("Image type not set"))
            }

            guard hasNextPage else { return .content }
            task?.cancel()
            task = Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        _ = self.backgroundStates.append(.gettingNextPage)
                    }

                    try await self.getNextPage(imageType)

                    await MainActor.run {
                        self.state = .content
                        _ = self.backgroundStates.remove(.gettingNextPage)
                    }
                } catch {
                    let apiError = JellyfinAPIError(error.localizedDescription)
                    await MainActor.run {
                        self.state = .error(apiError)
                        self.eventSubject.send(.error(apiError))
                        _ = self.backgroundStates.remove(.gettingNextPage)
                    }
                }
            }.asAnyCancellable()

            return state

        case let .setImage(url, index):
            guard let imageType else {
                logger.error("Image type not set")
                return .error(JellyfinAPIError("Image type not set"))
            }

            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.state = .updating
                    }

                    try await self.setImage(url, type: imageType)

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

        case let .uploadImage(image, index):
            guard let imageType else {
                logger.error("Image type not set")
                return .error(JellyfinAPIError("Image type not set"))
            }

            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.state = .updating
                    }

                    try await self.uploadImage(image, type: imageType, index: index)

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

        case let .deleteImage(index):
            guard let imageType else {
                logger.error("Image type not set")
                return .error(JellyfinAPIError("Image type not set"))
            }

            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.state = .updating
                    }

                    try await self.deleteImage(imageType, index: index)

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

        case .refresh:
            Task { [weak self] in
                guard let self else { return }
                do {
                    let localImages = try await self.getAllImages()

                    await MainActor.run {
                        self.localImages = localImages
                    }
                } catch {
                    await MainActor.run {
                        // self.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .store(in: &cancellables)

            return state
        }
    }

    // MARK: - Get All Images by Type

    private func getAllImages() async throws -> [String: [UIImage]] {
        guard let itemID = item.id else {
            logger.error("Item ID not found")
            return [:]
        }

        var imagesByType: [String: [UIImage]] = [:]

        for imageType in ImageType.allCases {
            var images: [UIImage] = []

            var index = 0
            while true {
                do {
                    let parameters = Paths.GetItemImageParameters(imageIndex: index)
                    let request = Paths.getItemImage(itemID: itemID, imageType: imageType.rawValue, parameters: parameters)
                    let response = try await userSession.client.send(request)

                    if let image = UIImage(data: response.value) {
                        images.append(image)
                    }

                    index += 1
                } catch {
                    break
                }
            }
            imagesByType[imageType.rawValue] = images
        }
        return imagesByType
    }

    // MARK: - Paging Logic

    private func getNextPage(_ type: ImageType) async throws {
        guard let itemID = item.id, hasNextPage else { return }

        let startIndex = currentPage * pageSize
        let parameters = Paths.GetRemoteImagesParameters(
            type: type,
            startIndex: startIndex,
            limit: pageSize,
            isIncludeAllLanguages: includeAllLanguages
        )

        let request = Paths.getRemoteImages(itemID: itemID, parameters: parameters)
        let response = try await userSession.client.send(request)
        let newImages = response.value.images ?? []

        hasNextPage = newImages.count >= pageSize

        await MainActor.run {
            remoteImages.append(contentsOf: newImages)
            currentPage += 1
        }
    }

    // MARK: - Set Image From URL

    private func setImage(_ url: String, type: ImageType) async throws {
        guard let itemID = item.id else { return }

        let parameters = Paths.DownloadRemoteImageParameters(type: type, imageURL: url)
        let imageRequest = Paths.downloadRemoteImage(itemID: itemID, parameters: parameters)
        try await userSession.client.send(imageRequest)

        try await refreshItem()
    }

    // MARK: - Upload Image

    private func uploadImage(_ image: UIImage, type: ImageType, index: Int = 0) async throws {
        guard let itemID = item.id else { return }

        var contentType: String
        let imageData: Data

        if let pngData = image.pngData()?.base64EncodedData() {
            contentType = "image/png"
            imageData = pngData
        } else if let jpgData = image.jpegData(compressionQuality: 1)?.base64EncodedData() {
            contentType = "image/jpeg"
            imageData = jpgData
        } else {
            logger.error("Unable to upload the the selected image")
            throw JellyfinAPIError("An internal error occurred")
        }

        var request = Paths.setItemImageByIndex(
            itemID: itemID,
            imageType: type.rawValue,
            imageIndex: index,
            imageData
        )
        request.headers = ["Content-Type": contentType]

        _ = try await userSession.client.send(request)

        try await refreshItem()
    }

    // MARK: - Delete Image

    private func deleteImage(_ type: ImageType, index: Int = 0) async throws {
        guard let itemID = item.id else { return }

        let request = Paths.deleteItemImageByIndex(
            itemID: itemID,
            imageType: type.rawValue,
            imageIndex: index
        )

        _ = try await userSession.client.send(request)

        await MainActor.run {
            if var images = localImages[type.rawValue], index < images.count {
                images.remove(at: index)
                localImages[type.rawValue] = images
            }
        }

        try await refreshItem()
    }

    // MARK: - Refresh Item

    private func refreshItem() async throws {
        guard let itemId = item.id else { return }

        await MainActor.run {
            _ = backgroundStates.append(.refreshing)
        }

        let request = Paths.getItem(
            userID: userSession.user.id,
            itemID: itemId
        )
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.item = response.value
            _ = backgroundStates.remove(.refreshing)
            Notifications[.itemMetadataDidChange].post(item)
        }
    }
}
