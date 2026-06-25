//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension DownloadManager {

    func queue(_ item: BaseItemDto, type: DownloadType = .direct) {
        Task {
            await queueAsync(item, type: type, parentID: nil)
        }
    }

    private func queueAsync(_ item: BaseItemDto, type: DownloadType, parentID: String?) async {
        guard currentUserID != nil else { return }
        guard let kind = item.type, let id = item.id else { return }

        do {
            let parentIDs: [String] = if let parentID {
                [parentID]
            } else {
                try await ensureAncestors(for: item)
            }

            switch kind {
            case .movie, .episode:
                try createMediaTask(item, type: type, parentIDs: parentIDs)

            case .series:
                createContainerTask(item, parentIDs: parentIDs)
                let seasons = try await getSeasons(seriesID: id)
                for season in seasons {
                    await queueAsync(season, type: type, parentID: id)
                }

            case .season, .boxSet:
                createContainerTask(item, parentIDs: parentIDs)
                let children = try await getChildren(parentID: id)
                for child in children {
                    await queueAsync(child, type: type, parentID: id)
                }

            default:
                return
            }
        } catch {
            logger.error("Failed to queue \(item.displayTitle): \(error.localizedDescription)")
        }

        advanceQueue()
    }

    // MARK: - Task creation

    private func createMediaTask(_ item: BaseItemDto, type: DownloadType, parentIDs: [String]) throws {
        guard let id = item.id else { return }
        if task(id: id) != nil { return }

        let newTask = try DownloadTask(item: item, kind: .media(type), parentIDs: parentIDs)
        tasks.append(newTask)
        persistTasks()
    }

    private func createContainerTask(_ item: BaseItemDto, parentIDs: [String]) {
        guard let id = item.id else { return }
        if task(id: id) != nil { return }

        guard let newTask = try? DownloadTask(item: item, kind: .container, parentIDs: parentIDs) else { return }
        tasks.append(newTask)
        persistTasks()
    }

    // MARK: - Ancestor resolution

    private func ensureAncestors(for item: BaseItemDto) async throws -> [String] {
        switch item.type {
        case .episode:
            if let seasonID = item.seasonID {
                try await ensureContainer(id: seasonID)
                return [seasonID]
            }
            if let seriesID = item.seriesID {
                try await ensureContainer(id: seriesID)
                return [seriesID]
            }
            return []
        case .season:
            if let seriesID = item.seriesID {
                try await ensureContainer(id: seriesID)
                return [seriesID]
            }
            return []
        default:
            return []
        }
    }

    private func ensureContainer(id: String) async throws {
        guard task(id: id) == nil else { return }
        let item = try await fetchItem(id: id)
        let parentIDs = try await ensureAncestors(for: item)
        createContainerTask(item, parentIDs: parentIDs)
    }

    // MARK: - Server fetches

    private func fetchItem(id: String) async throws -> BaseItemDto {
        guard let userSession else { throw URLError(.userAuthenticationRequired) }
        let request = Paths.getItem(itemID: id, userID: userSession.user.id)
        let response = try await userSession.client.send(request)
        return response.value
    }

    private func getSeasons(seriesID: String) async throws -> [BaseItemDto] {
        guard let userSession else { throw URLError(.userAuthenticationRequired) }
        var parameters = Paths.GetSeasonsParameters()
        parameters.userID = userSession.user.id
        parameters.fields = .MinimumFields
        let request = Paths.getSeasons(seriesID: seriesID, parameters: parameters)
        let response = try await userSession.client.send(request)
        return response.value.items ?? []
    }

    private func getChildren(parentID: String) async throws -> [BaseItemDto] {
        guard let userSession else { throw URLError(.userAuthenticationRequired) }
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userSession.user.id
        parameters.parentID = parentID
        parameters.includeItemTypes = [.movie, .series, .episode]
        parameters.fields = .MinimumFields
        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)
        return response.value.items ?? []
    }
}
