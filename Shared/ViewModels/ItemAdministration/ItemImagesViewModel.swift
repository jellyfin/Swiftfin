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
import UIKit

class ItemImagesViewModel: ViewModel, Stateful, Eventful {

    enum Event: Equatable {
        case updated
        case deleted
        case error(JellyfinAPIError)
    }

    enum Action: Equatable {
        case refresh
        case setImage(url: String, type: ImageType)
        case uploadImage(image: UIImage, type: ImageType, index: Int = 0)
        case deleteImage(type: ImageType, index: Int = 0)
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
    var images: [String: [UIImage]] = [:]

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
    }

    // MARK: - Respond to Actions

    func respond(to action: Action) -> State {
        switch action {

        case .refresh:
            task?.cancel()

            task = Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        self.state = .initial
                        self.images.removeAll()
                        _ = self.backgroundStates.append(.refreshing)
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

        case let .setImage(url, imageType):
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

        case let .uploadImage(image, imageType, index):
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

        case let .deleteImage(imageType, index):
            task?.cancel()

            task = Task { [weak self] in
                guard let self = self else { return }
                do {
                    await MainActor.run {
                        _ = self.state = .deleting
                    }

                    try await self.deleteImage(imageType, index: index)

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

    // MARK: - Get All Images by Type

    private func getAllImages() async throws {
        guard let itemID = item.id else { return }

        let results = try await withThrowingTaskGroup(of: (String, [UIImage]).self) { group -> [String: [UIImage]] in
            for imageType in ImageType.allCases {
                group.addTask {
                    var images: [UIImage] = []
                    var index = 0

                    while true {
                        do {
                            let parameters = Paths.GetItemImageParameters(imageIndex: index)
                            let request = Paths.getItemImage(itemID: itemID, imageType: imageType.rawValue, parameters: parameters)
                            let response = try await self.userSession.client.send(request)

                            if let image = UIImage(data: response.value) {
                                images.append(image)
                            }

                            index += 1
                        } catch {
                            break
                        }
                    }

                    return (imageType.rawValue, images)
                }
            }

            var collectedResults: [String: [UIImage]] = [:]
            for try await (key, images) in group {
                collectedResults[key] = images
            }
            return collectedResults
        }

        await MainActor.run {
            self.images = results
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

    // TODO: Make actually work. 500 error. Bad format.
    private func uploadImage(_ image: UIImage, type: ImageType, index: Int = 0) async throws {
        guard let itemID = item.id else { return }

        let contentType: String
        let imageData: Data

        if let pngData = image.pngData() {
            contentType = "image/png"
            imageData = pngData
        } else if let jpgData = image.jpegData(compressionQuality: 1) {
            contentType = "image/jpeg"
            imageData = jpgData
        } else {
            logger.error("Unable to upload the selected image")
            throw JellyfinAPIError("An internal error occurred")
        }

        var request = Paths.setItemImageByIndex(
            itemID: itemID,
            imageType: type.rawValue,
            imageIndex: index,
            imageData.base64EncodedData()
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
            if var typeImages = images[type.rawValue], index < typeImages.count {
                typeImages.remove(at: index)
                images[type.rawValue] = typeImages
            }
            Notifications[.itemMetadataDidChange].post(item)
        }
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
