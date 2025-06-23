//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

final class PersonItemViewModel: ItemViewModel {

    // MARK: - Published Collection Items

    @Published
    private(set) var personItems: OrderedDictionary<BaseItemKind, [BaseItemDto]> = [:]

    // MARK: - Task

    private var personItemTask: AnyCancellable?

    // MARK: - Disable PlayButton

    override var presentPlayButton: Bool {
        false
    }

    // MARK: - Override Response

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {

        switch action {
        case .backgroundRefresh, .refresh:

            personItemTask?.cancel()

            Task { [weak self] in
                guard let self else { return }

                await MainActor.run {
                    self.personItems.removeAll()
                }

                do {
                    let personItems = try await self.getPersonItems()

                    await MainActor.run {
                        self.personItems = personItems
                    }
                }
            }
            .store(in: &cancellables)
        default: ()
        }

        return super.respond(to: action)
    }

    // MARK: - Get Person Items

    private func getPersonItems() async throws -> OrderedDictionary<BaseItemKind, [BaseItemDto]> {
        guard let itemID = item.id else {
            throw JellyfinAPIError(L10n.unknownError)
        }

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = BaseItemKind.supportedCases
            .appending(.episode)
        parameters.personIDs = [itemID]
        parameters.isRecursive = true

        let request = Paths.getItemsByUserID(
            userID: userSession.user.id,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        let items = response.value.items ?? []

        let result = OrderedDictionary<BaseItemKind?, [BaseItemDto]>(
            grouping: items,
            by: \.type
        )
        .compactKeys()
        .sortedKeys { $0.rawValue < $1.rawValue }

        return result
    }
}
