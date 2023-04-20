//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Factory
import Foundation
import JellyfinAPI
import UIKit

final class HomeViewModel: ViewModel {

    @Published
    var errorMessage: String?
    @Published
    var hasNextUp: Bool = false
    @Published
    var hasRecentlyAdded: Bool = false
    @Published
    var libraries: [BaseItemDto] = []
    @Published
    var resumeItems: [BaseItemDto] = []

    override init() {
        super.init()

        refresh()
    }

    @objc
    func refresh() {

        hasNextUp = false
        hasRecentlyAdded = false
        libraries = []
        resumeItems = []

        Task {
            logger.debug("Refreshing home screen")

            await MainActor.run {
                isLoading = true
            }

            refreshHasRecentlyAddedItems()
            refreshResumeItems()
            refreshHasNextUp()

            do {
                try await refreshLibrariesLatest()
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }

                return
            }

            await MainActor.run {
                isLoading = false
                errorMessage = nil
            }
        }
    }

    // MARK: Libraries Latest Items

    private func refreshLibrariesLatest() async throws {
        let userViewsPath = Paths.getUserViews(userID: userSession.user.id)
        let response = try await userSession.client.send(userViewsPath)

        guard let allLibraries = response.value.items else {
            await MainActor.run {
                libraries = []
            }

            return
        }

        let excludedLibraryIDs = await getExcludedLibraries()

        let newLibraries = allLibraries
            .filter { $0.collectionType == "movies" || $0.collectionType == "tvshows" }
            .filter { library in
                !excludedLibraryIDs.contains(where: { $0 == library.id ?? "" })
            }

        await MainActor.run {
            libraries = newLibraries
        }
    }

    private func getExcludedLibraries() async -> [String] {
        let currentUserPath = Paths.getCurrentUser
        let response = try? await userSession.client.send(currentUserPath)

        return response?.value.configuration?.latestItemsExcludes ?? []
    }

    // MARK: Recently Added Items

    private func refreshHasRecentlyAddedItems() {
        Task {
            let parameters = Paths.GetLatestMediaParameters(
                includeItemTypes: [.movie, .series],
                limit: 1
            )
            let request = Paths.getLatestMedia(userID: userSession.user.id, parameters: parameters)
            let response = try await userSession.client.send(request)

            await MainActor.run {
                hasRecentlyAdded = !response.value.isEmpty
            }
        }
    }

    // MARK: Resume Items

    private func refreshResumeItems() {
        Task {
            let resumeParameters = Paths.GetResumeItemsParameters(
                limit: 20,
                fields: ItemFields.minimumCases,
                enableUserData: true,
                includeItemTypes: [.movie, .episode]
            )

            let request = Paths.getResumeItems(userID: userSession.user.id, parameters: resumeParameters)
            let response = try await userSession.client.send(request)

            guard let items = response.value.items else { return }

            await MainActor.run {
                resumeItems = items
            }
        }
    }

    func markItemUnplayed(_ item: BaseItemDto) {
        guard resumeItems.contains(where: { $0.id == item.id! }) else { return }

        Task {
            let request = Paths.markUnplayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
            let _ = try await userSession.client.send(request)

            refreshResumeItems()
            refreshHasNextUp()
        }
    }

    func markItemPlayed(_ item: BaseItemDto) {
        guard resumeItems.contains(where: { $0.id == item.id! }) else { return }

        Task {
            let request = Paths.markPlayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
            let _ = try await userSession.client.send(request)

            refreshResumeItems()
            refreshHasNextUp()
        }
    }

    // MARK: Next Up Items

    private func refreshHasNextUp() {
        Task {
            let parameters = Paths.GetNextUpParameters(
                userID: userSession.user.id,
                limit: 1
            )
            let request = Paths.getNextUp(parameters: parameters)
            let response = try await userSession.client.send(request)

            await MainActor.run {
                hasNextUp = !(response.value.items?.isEmpty ?? true)
            }
        }
    }
}
