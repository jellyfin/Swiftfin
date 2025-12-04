//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class YouTubeLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {

    @Published
    private(set) var channels: [BaseItemDto] = []

    @Published
    var selectedChannelID: String? {
        didSet {
            Task { @MainActor in
                self.send(.refresh)
            }
        }
    }

    private let library: BaseItemDto

    init(library: BaseItemDto) {
        self.library = library
        super.init(parent: library, filters: nil)

        Task { [weak self] in
            await self?.loadChannels()
        }
    }

    override func get(page: Int) async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsByUserIDParameters()

        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.episode, .video]
        parameters.sortBy = [ItemSortBy.premiereDate.rawValue, ItemSortBy.dateCreated.rawValue]
        parameters.sortOrder = [.descending]
        parameters.isRecursive = true
        parameters.parentID = selectedChannelID ?? library.id
        parameters.limit = pageSize
        parameters.startIndex = page * pageSize

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    @MainActor
    private func loadChannels() async {
        do {
            channels = try await fetchChannels()
        } catch {
            logger.error("Failed to load channels: \(error.localizedDescription)")
        }
    }

    private func fetchChannels() async throws -> [BaseItemDto] {
        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.series]
        parameters.sortBy = [ItemSortBy.sortName.rawValue]
        parameters.sortOrder = [.ascending]
        parameters.parentID = library.id

        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
