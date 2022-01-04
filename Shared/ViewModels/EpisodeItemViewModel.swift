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
    var seasonEpisodes: [BaseItemDto] = []
    
    override init(item: BaseItemDto) {
        super.init(item: item)
        
        getSeasonEpisodes()
    }

    override func getItemDisplayName() -> String {
        guard let episodeLocator = item.getEpisodeLocator() else { return item.name ?? "" }
        return "\(episodeLocator)\n\(item.name ?? "")"
    }

    override func shouldDisplayRuntime() -> Bool {
        return false
    }

    func routeToSeasonItem() {
        guard let id = item.seasonId else { return }
        UserLibraryAPI.getItem(userId: SessionManager.main.currentLogin.user.id, itemId: id)
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
        UserLibraryAPI.getItem(userId: SessionManager.main.currentLogin.user.id, itemId: id)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] item in
                self?.itemRouter?.route(to: \.item, item)
            })
            .store(in: &cancellables)
    }
    
    private func getSeasonEpisodes() {
        guard let seriesID = item.seriesId else { return }
        TvShowsAPI.getEpisodes(seriesId: seriesID,
                               userId: SessionManager.main.currentLogin.user.id,
                               fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                               seasonId: item.seasonId ?? "")
            .sink { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            } receiveValue: { [weak self] item in
                self?.seasonEpisodes = item.items ?? []
            }
            .store(in: &cancellables)
    }
}
