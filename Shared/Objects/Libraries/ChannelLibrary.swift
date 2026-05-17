//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct ChannelLibrary: PagingLibrary {

    let parent: TitledLibraryParent = .init(displayTitle: L10n.channels, id: "channels")

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ChannelProgram] {
        var parameters = Paths.GetLiveTvChannelsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = pageState.pageSize
        parameters.sortBy = [.name]
        parameters.startIndex = pageState.pageOffset

        let request = Paths.getLiveTvChannels(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try await getPrograms(
            for: response.value.items ?? [],
            pageState: pageState
        )
    }

    private func getPrograms(
        for channels: [BaseItemDto],
        pageState: LibraryPageState
    ) async throws -> [ChannelProgram] {
        guard let minEndDate = Calendar.current.date(byAdding: .hour, value: -1, to: .now),
              let maxStartDate = Calendar.current.date(byAdding: .hour, value: 6, to: .now)
        else { return [] }

        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.channelIDs = channels.compactMap(\.id)
        parameters.maxStartDate = maxStartDate
        parameters.minEndDate = minEndDate
        parameters.sortBy = [.startDate]
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getLiveTvPrograms(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        let groupedPrograms = (response.value.items ?? [])
            .grouped { program in
                channels.first(where: { $0.id == program.channelID })
            }

        return channels
            .reduce(into: [:]) { partialResult, channel in
                partialResult[channel] = (groupedPrograms[channel] ?? [])
                    .sorted(using: \.startDate)
            }
            .map(ChannelProgram.init)
            .sorted(using: \.channel.name)
    }
}
