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
            await queueAsync(item, type: type)
        }
    }

    private func queueAsync(_ item: BaseItemDto, type: DownloadType) async {
        guard currentUserID != nil else { return }
        guard let kind = item.type else { return }

        do {
            switch kind {
            case .movie, .episode:
                try await createMediaTask(item, type: type)
            case .series:
                guard let id = item.id else { return }
                let seasons = try await getSeasons(seriesID: id)
                for season in seasons {
                    await queueAsync(season, type: type)
                }
            case .boxSet, .season:
                guard let id = item.id else { return }
                let children = try await getChildren(parentID: id)
                for child in children {
                    await queueAsync(child, type: type)
                }
            default:
                return
            }
        } catch {
            logger.error("Failed to queue \(item.displayTitle): \(error.localizedDescription)")
        }

        advanceQueue()
    }

    private func createMediaTask(_ item: BaseItemDto, type: DownloadType) async throws {
        guard let id = item.id else { return }
        if task(id: id) != nil { return }

        let task = try DownloadTask(item: item, type: type)
        tasks.append(task)
        persistTasks()
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
