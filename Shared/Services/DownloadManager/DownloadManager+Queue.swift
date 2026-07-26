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

    func queue(_ item: BaseItemDto, parameters: DownloadParameters? = nil) {
        let parameters = parameters ?? .video

        Task {
            await queueAsync(item, parameters: parameters, parentID: nil)
        }
    }

    private func queueAsync(_ item: BaseItemDto, parameters: DownloadParameters, parentID: String?) async {
        guard currentUserID != nil else { return }
        guard let kind = item.type, let id = item.id else { return }

        do {
            let parentIDs: [String] = if let parentID {
                [parentID]
            } else {
                try await ensureAncestors(for: item, parameters: parameters)
            }

            switch kind {
            case .movie, .episode:
                try createMediaTask(item, parameters: parameters, parentIDs: parentIDs)

            case .series:
                createContainerTask(item, parameters: parameters, parentIDs: parentIDs)
                let seasons = try await getSeasons(seriesID: id)
                for season in seasons {
                    await queueAsync(season, parameters: parameters, parentID: id)
                }

            case .season, .boxSet:
                createContainerTask(item, parameters: parameters, parentIDs: parentIDs)
                let children = try await getChildren(parentID: id)
                for child in children {
                    await queueAsync(child, parameters: parameters, parentID: id)
                }

            case .person:
                createContainerTask(item, parameters: parameters, parentIDs: parentIDs)
                let media = try await getPersonMedia(personID: id)
                for child in media {
                    await queueAsync(child, parameters: parameters, parentID: id)
                }

            default:
                return
            }
        } catch {
            logger.error("Failed to queue \(item.displayTitle): \(error.localizedDescription)")
        }

        advanceQueue()
    }

    func downloadableItemCount(for item: BaseItemDto) async throws -> Int {
        guard let id = item.id else { return 0 }

        switch item.type {
        case .movie, .episode:
            return 1
        case .series, .season, .boxSet, .person:
            guard let userSession else { throw UserSessionError.missingCurrentSession }
            var parameters = Paths.GetItemsParameters()
            parameters.userID = userSession.user.id
            parameters.isRecursive = true
            parameters.includeItemTypes = [.movie, .episode]
            parameters.limit = 1
            parameters.enableTotalRecordCount = true

            if item.type == .person {
                parameters.personIDs = [id]
            } else {
                parameters.parentID = id
            }

            let request = Paths.getItems(parameters: parameters)
            let response = try await userSession.client.send(request)
            return response.value.totalRecordCount ?? 0
        default:
            return 0
        }
    }

    // MARK: - Task creation

    private func createMediaTask(_ item: BaseItemDto, parameters: DownloadParameters, parentIDs: [String]) throws {
        guard let id = item.id else { return }
        if task(id: id) != nil { return }

        let newTask = try DownloadTask(item: item, kind: .media, parameters: parameters, parentIDs: parentIDs)
        tasks.append(newTask)
        persistTasks()
    }

    private func createContainerTask(_ item: BaseItemDto, parameters: DownloadParameters, parentIDs: [String]) {
        guard let id = item.id else { return }
        if task(id: id) != nil { return }

        guard let newTask = try? DownloadTask(item: item, kind: .container, parameters: parameters, parentIDs: parentIDs)
        else { return }
        tasks.append(newTask)
        persistTasks()
    }

    // MARK: - Ancestor resolution

    private func ensureAncestors(for item: BaseItemDto, parameters: DownloadParameters) async throws -> [String] {
        switch item.type {
        case .episode:
            if let seasonID = item.seasonID {
                try await ensureContainer(id: seasonID, parameters: parameters)
                return [seasonID]
            }
            if let seriesID = item.seriesID {
                try await ensureContainer(id: seriesID, parameters: parameters)
                return [seriesID]
            }
            return []
        case .season:
            if let seriesID = item.seriesID {
                try await ensureContainer(id: seriesID, parameters: parameters)
                return [seriesID]
            }
            return []
        default:
            return []
        }
    }

    private func ensureContainer(id: String, parameters: DownloadParameters) async throws {
        guard task(id: id) == nil else { return }
        guard let userSession else { throw UserSessionError.missingCurrentSession }
        let item = try await BaseItemDto(id: id).getFullItem(userSession: userSession)
        let parentIDs = try await ensureAncestors(for: item, parameters: parameters)
        createContainerTask(item, parameters: parameters, parentIDs: parentIDs)
    }

    // MARK: - Server fetches

    private static let queueFields: [ItemFields] = .MinimumFields
        .appending([.people, .overview, .genres, .tags, .trickplay])

    private func getSeasons(seriesID: String) async throws -> [BaseItemDto] {
        guard let userSession else { throw UserSessionError.missingCurrentSession }
        var parameters = Paths.GetSeasonsParameters()
        parameters.userID = userSession.user.id
        parameters.fields = Self.queueFields
        let request = Paths.getSeasons(seriesID: seriesID, parameters: parameters)
        let response = try await userSession.client.send(request)
        return response.value.items ?? []
    }

    private func getChildren(parentID: String) async throws -> [BaseItemDto] {
        guard let userSession else { throw UserSessionError.missingCurrentSession }
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userSession.user.id
        parameters.parentID = parentID
        parameters.includeItemTypes = [.movie, .series, .episode]
        parameters.fields = Self.queueFields
        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)
        return response.value.items ?? []
    }

    private func getPersonMedia(personID: String) async throws -> [BaseItemDto] {
        guard let userSession else { throw UserSessionError.missingCurrentSession }
        var parameters = Paths.GetItemsParameters()
        parameters.userID = userSession.user.id
        parameters.personIDs = [personID]
        parameters.isRecursive = true
        parameters.includeItemTypes = [.movie, .series]
        parameters.fields = Self.queueFields
        let request = Paths.getItems(parameters: parameters)
        let response = try await userSession.client.send(request)
        return response.value.items ?? []
    }
}
