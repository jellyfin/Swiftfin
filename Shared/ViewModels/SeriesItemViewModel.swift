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

final class SeriesItemViewModel: ItemViewModel {

    @Published var seasons: [BaseItemDto] = []

    override init(item: BaseItemDto) {
        super.init(item: item)

        requestSeasons()
        getNextUp()
    }
    
    override func playButtonText() -> String {
        guard let playButtonItem = playButtonItem else { return "Play" }
        guard let episodeLocator = playButtonItem.getEpisodeLocator() else { return "Play" }
        return episodeLocator
    }
    
    override func shouldDisplayRuntime() -> Bool {
        return false
    }

    private func getNextUp() {        
        
        LogManager.shared.log.debug("Getting next up for show \(self.item.id!) (\(self.item.name!))")
        TvShowsAPI.getNextUp(userId: SessionManager.main.currentLogin.user.id, fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people], seriesId: self.item.id!, enableUserData: true)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                if let nextUpItem = response.items?.first {
                    self?.playButtonItem = nextUpItem
                }
            })
            .store(in: &cancellables)
    }

    private func getRunYears() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"

        var startYear: String?
        var endYear: String?

        if item.premiereDate != nil {
            startYear = dateFormatter.string(from: item.premiereDate!)
        }

        if item.endDate != nil {
            endYear = dateFormatter.string(from: item.endDate!)
        }

        return "\(startYear ?? "Unknown") - \(endYear ?? "Present")"
    }

    private func requestSeasons() {
        LogManager.shared.log.debug("Getting seasons of show \(self.item.id!) (\(self.item.name!))")
        TvShowsAPI.getSeasons(seriesId: item.id ?? "", userId: SessionManager.main.currentLogin.user.id, fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people], enableUserData: true)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.seasons = response.items ?? []
                LogManager.shared.log.debug("Retrieved \(String(self?.seasons.count ?? 0)) seasons")
            })
            .store(in: &cancellables)
    }
}
