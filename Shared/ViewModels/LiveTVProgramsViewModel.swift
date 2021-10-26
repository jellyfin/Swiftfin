//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Foundation
import JellyfinAPI

final class LiveTVProgramsViewModel: ViewModel {
    
    @Published var recommendedItems = [BaseItemDto]()
    @Published var seriesItems = [BaseItemDto]()
    @Published var movieItems = [BaseItemDto]()
    @Published var sportsItems = [BaseItemDto]()
    @Published var kidsItems = [BaseItemDto]()
    @Published var newsItems = [BaseItemDto]()
    
    override init() {
        super.init()
        
        loadRecommendedPrograms()
        loadSeries()
        loadMovies()
        loadSports()
        loadKids()
        loadNews()
    }
    
    private func loadRecommendedPrograms() {
        LiveTvAPI.getRecommendedPrograms(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 9,
            isAiring: true,
            imageTypeLimit: 1,
            enableImageTypes: [.primary, .thumb],
            fields: [.channelInfo, .primaryImageAspectRatio],
            enableTotalRecordCount: false
        )
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            LogManager.shared.log.debug("Received \(String(response.items?.count ?? 0)) Recommended Programs")
            guard let self = self else { return }
            self.recommendedItems = response.items ?? []
        })
        .store(in: &cancellables)
    }
    
    private func loadSeries() {
        let getProgramsDto = GetProgramsDto(userId: SessionManager.main.currentLogin.user.id,
                hasAired: false,
                isMovie: false,
                isSeries: true,
                isNews: false,
                isKids: false,
                isSports: false,
                limit: 9,
                enableTotalRecordCount: false,
                enableImageTypes: [.primary, .thumb],
                fields: [.channelInfo, .primaryImageAspectRatio]
            )
        
        LiveTvAPI.getPrograms(getProgramsDto:  getProgramsDto)
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            LogManager.shared.log.debug("Received \(String(response.items?.count ?? 0)) Series Items")
            guard let self = self else { return }
            self.seriesItems = response.items ?? []
        })
        .store(in: &cancellables)
    }
    
    private func loadMovies() {
        let getProgramsDto = GetProgramsDto(userId: SessionManager.main.currentLogin.user.id,
                hasAired: false,
                isMovie: true,
                isSeries: false,
                isNews: false,
                isKids: false,
                isSports: false,
                limit: 9,
                enableTotalRecordCount: false,
                enableImageTypes: [.primary, .thumb],
                fields: [.channelInfo, .primaryImageAspectRatio]
            )
        
        LiveTvAPI.getPrograms(getProgramsDto:  getProgramsDto)
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            LogManager.shared.log.debug("Received \(String(response.items?.count ?? 0)) Movie Items")
            guard let self = self else { return }
            self.movieItems = response.items ?? []
        })
        .store(in: &cancellables)
    }
    
    private func loadSports() {
        let getProgramsDto = GetProgramsDto(userId: SessionManager.main.currentLogin.user.id,
                hasAired: false,
                isSports: true,
                limit: 9,
                enableTotalRecordCount: false,
                enableImageTypes: [.primary, .thumb],
                fields: [.channelInfo, .primaryImageAspectRatio]
            )
        
        LiveTvAPI.getPrograms(getProgramsDto:  getProgramsDto)
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            LogManager.shared.log.debug("Received \(String(response.items?.count ?? 0)) Sports Items")
            guard let self = self else { return }
            self.sportsItems = response.items ?? []
        })
        .store(in: &cancellables)
    }
    
    private func loadKids() {
        let getProgramsDto = GetProgramsDto(userId: SessionManager.main.currentLogin.user.id,
                hasAired: false,
                isKids: true,
                limit: 9,
                enableTotalRecordCount: false,
                enableImageTypes: [.primary, .thumb],
                fields: [.channelInfo, .primaryImageAspectRatio]
            )
        
        LiveTvAPI.getPrograms(getProgramsDto:  getProgramsDto)
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            LogManager.shared.log.debug("Received \(String(response.items?.count ?? 0)) Kids Items")
            guard let self = self else { return }
            self.kidsItems = response.items ?? []
        })
        .store(in: &cancellables)
    }
    
    private func loadNews() {
        let getProgramsDto = GetProgramsDto(userId: SessionManager.main.currentLogin.user.id,
                hasAired: false,
                isNews: true,
                limit: 9,
                enableTotalRecordCount: false,
                enableImageTypes: [.primary, .thumb],
                fields: [.channelInfo, .primaryImageAspectRatio]
            )
        
        LiveTvAPI.getPrograms(getProgramsDto:  getProgramsDto)
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            LogManager.shared.log.debug("Received \(String(response.items?.count ?? 0)) News Items")
            guard let self = self else { return }
            self.newsItems = response.items ?? []
        })
        .store(in: &cancellables)
    }
}
