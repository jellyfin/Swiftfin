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

class RemoteImageInfoViewModel: ViewModel, Stateful {

    enum Event: Equatable {
        case updated
        case error(JellyfinAPIError)
    }

    enum Action: Equatable {
        case cancel
        case refresh
        case getNextPage
        case setImage(url: String, type: ImageType)
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
    var imageType: ImageType
    @Published
    var includeAllLanguages: Bool
    @Published
    var images: IdentifiedArrayOf<RemoteImageInfo> = []

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

    // MARK: - Initializer

    init(
        item: BaseItemDto,
        imageType: ImageType,
        includeAllLanguages: Bool = false,
        pageSize: Int = DefaultPageSize
    ) {
        self.item = item
        self.imageType = imageType
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

        case .refresh:
            task?.cancel()

            task = Task { [weak self] in
                guard let self else { return }
                do {
                    await MainActor.run {
                        self.state = .initial
                        self.images.removeAll()
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
                        _ = self.backgroundStates.remove(.refreshing)
                    }
                }
            }.asAnyCancellable()

            return state

        case .getNextPage:
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
                        _ = self.backgroundStates.remove(.gettingNextPage)
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
        }
    }

    // MARK: - Get Next Page

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
            self.images.append(contentsOf: newImages)
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
