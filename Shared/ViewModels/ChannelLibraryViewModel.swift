//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI

final class ChannelLibraryViewModel: PagingLibraryViewModel<ChannelProgram> {

    override func get(page: Int) async throws -> [ChannelProgram] {

        var parameters = Paths.GetLiveTvChannelsParameters()
        parameters.fields = .MinimumFields
        parameters.userID = userSession.user.id
        parameters.sortBy = [ItemSortBy.name]

        parameters.limit = pageSize
        parameters.startIndex = page * pageSize

        let request = Paths.getLiveTvChannels(parameters: parameters)
        let response = try await userSession.client.send(request)

        let processedChannels = try await getPrograms(for: response.value.items ?? [])

        return processedChannels
    }

    private func getPrograms(for channels: [BaseItemDto]) async throws -> [ChannelProgram] {

        guard let minEndDate = Calendar.current.date(byAdding: .hour, value: -1, to: .now),
              let maxStartDate = Calendar.current.date(byAdding: .hour, value: 6, to: .now) else { return [] }

        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.channelIDs = channels.compactMap(\.id)
        parameters.userID = userSession.user.id
        parameters.maxStartDate = maxStartDate
        parameters.minEndDate = minEndDate
        parameters.sortBy = [ItemSortBy.startDate]

        let request = Paths.getLiveTvPrograms(parameters: parameters)
        let response = try await userSession.client.send(request)

        let groupedPrograms = (response.value.items ?? [])
            .grouped { program in
                channels.first(where: { $0.id == program.channelID })
            }

        let channelPrograms: [ChannelProgram] = channels
            .reduce(into: [:]) { partialResult, channel in
                partialResult[channel] = (groupedPrograms[channel] ?? [])
                    .sorted(using: \.startDate)
            }
            .map(ChannelProgram.init)
            .sorted(using: \.channel.name)

        return channelPrograms
    }
}
