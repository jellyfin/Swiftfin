//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import JellyfinAPI
import SwiftUI

final class EpisodesRowViewModel: ViewModel {
    
    // TODO: Protocol these viewmodels for generalization instead of Episode
    
    @ObservedObject var episodeItemViewModel: EpisodeItemViewModel
    @Published var seasonsEpisodes: [BaseItemDto: [BaseItemDto]] = [:]
    @Published var selectedSeason: BaseItemDto? {
        willSet {
            if seasonsEpisodes[newValue!]!.isEmpty {
                retrieveEpisodesForSeason(newValue!)
            }
        }
    }
    
    init(episodeItemViewModel: EpisodeItemViewModel) {
        self.episodeItemViewModel = episodeItemViewModel
        super.init()
        
        retrieveSeasons()
    }
    
    private func retrieveSeasons() {
        TvShowsAPI.getSeasons(seriesId: episodeItemViewModel.item.seriesId ?? "",
                              userId: SessionManager.main.currentLogin.user.id)
            .sink { completion in
                self.handleAPIRequestError(completion: completion)
            } receiveValue: { response in
                let seasons = response.items ?? []
                seasons.forEach { season in
                    self.seasonsEpisodes[season] = []
                    
                    if season.id == self.episodeItemViewModel.item.seasonId ?? "" {
                        self.selectedSeason = season
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func retrieveEpisodesForSeason(_ season: BaseItemDto) {
        guard let seasonID = season.id else { return }
        
        TvShowsAPI.getEpisodes(seriesId: episodeItemViewModel.item.seriesId ?? "",
                               userId: SessionManager.main.currentLogin.user.id,
                               fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                               seasonId: seasonID)
            .trackActivity(loading)
            .sink { completion in
                self.handleAPIRequestError(completion: completion)
            } receiveValue: { episodes in
                self.seasonsEpisodes[season] = episodes.items ?? []
            }
            .store(in: &cancellables)
    }
}

final class SingleSeasonEpisodesRowViewModel: ViewModel {
    
    // TODO: Protocol these viewmodels for generalization instead of Season
    
    @ObservedObject var seasonItemViewModel: SeasonItemViewModel
    @Published var episodes: [BaseItemDto]
    
    init(seasonItemViewModel: SeasonItemViewModel) {
        self.seasonItemViewModel = seasonItemViewModel
        self.episodes = seasonItemViewModel.episodes
        super.init()
    }
}
