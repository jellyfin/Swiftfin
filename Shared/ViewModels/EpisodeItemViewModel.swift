//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import Foundation
import JellyfinAPI
import Stinsen

final class EpisodeItemViewModel: ItemViewModel {
    @RouterObject var itemRouter: ItemCoordinator.Router?

    override func getItemDisplayName() -> String {
        guard let episodeLocator = item.getEpisodeLocator() else { return item.name ?? "" }
        return "\(episodeLocator)\n\(item.name ?? "")"
    }

    override func shouldDisplayRuntime() -> Bool {
        return false
    }

    func routeToSeasonItem() {
        guard let id = item.seasonId else { return }
        UserLibraryAPI.getItem(userId: SessionManager.current.user.user_id!, itemId: id)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] item in
                self?.itemRouter?.route(to: \.item, item)
            })
            .store(in: &cancellables)
    }

    func routeToSeriesItem() {
        guard let id = item.seriesId else { return }
        UserLibraryAPI.getItem(userId: SessionManager.current.user.user_id!, itemId: id)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] item in
                self?.itemRouter?.route(to: \.item, item)
            })
            .store(in: &cancellables)
    }
}
