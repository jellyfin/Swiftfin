//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Factory
import Foundation
import JellyfinAPI
import UIKit

final class HomeViewModel: ViewModel, Stateful {
    
    // MARK: State/Event
    
    enum State {
        case loading
        case error(Error)
        case results
    }
    
    enum Event {
        case getLibraries
        case error(Error)
        case refresh
        case markItemPlayed(BaseItemDto)
        case markItemUnplayed(BaseItemDto)
        case showContent
    }
    
    // MARK: Properties

    @Published
    var libraries: [BaseItemDto] = []
    @Published
    var resumeItems: [BaseItemDto] = []
    
    let nextUpLibraryViewModel: NextUpLibraryViewModel
    
    private var refreshTask: Task<Void, Error>?
    
    @Published
    var state: State = .loading
    
    // MARK: init

    override init() {
        
        self.nextUpLibraryViewModel = .init()
        
        super.init()

//        refresh()
    }
    
    // MARK: respond
    
    func respond(to action: Event) -> State {
        switch action {
        case .getLibraries:
            
            refreshTask = Task {
                await refresh()
            }
            
            return .loading
        case .error(let error):
            return .error(error)
        case .refresh:
            
            refreshTask?.cancel()
            refreshTask = Task {
                await refresh()
            }
            
            return .results
        case .markItemPlayed(let baseItemDto):
            return .results
        case .markItemUnplayed(let baseItemDto):
            return .results
        case .showContent:
            return .results
        }
    }
    
    // MARK: refresh

    func refresh() async {

//        hasNextUp = false
//        hasRecentlyAdded = false
        await MainActor.run {
            libraries = []
            resumeItems = []
        }
        
        Task {
            await nextUpLibraryViewModel.refresh()
        }

//        refreshHasRecentlyAddedItems()
//        refreshResumeItems()
//        refreshHasNextUp()

        do {
            let newLibraries = try await getLibrariesLatest()
            
            await MainActor.run {
                libraries = newLibraries
                send(.showContent)
            }
        } catch {
            await send(.error(error))
            return
        }
    }

    // MARK: Libraries Latest Items

    private func getLibrariesLatest() async throws -> [BaseItemDto] {
        let userViewsPath = Paths.getUserViews(userID: userSession.user.id)
        
        async let userViewsResponse = try userSession.client.send(userViewsPath)
        async let excludedLibraries = getExcludedLibraries()
        
        guard let userViews = try await userViewsResponse.value.items else {
            return []
        }
        
        let newLibraries = userViews
            .filter { $0.collectionType == "movies" || $0.collectionType == "tvshows" }
            .subtracting(try await excludedLibraries, using: \.id)
        
        return newLibraries
    }

    private func getExcludedLibraries() async throws -> [String?] {
        let currentUserPath = Paths.getCurrentUser
        let response = try await userSession.client.send(currentUserPath)

        return response.value.configuration?.latestItemsExcludes ?? []
    }

    // MARK: Recently Added Items

//    private func refreshHasRecentlyAddedItems() {
//        Task {
//            let parameters = Paths.GetLatestMediaParameters(
//                includeItemTypes: [.movie, .series],
//                limit: 1
//            )
//            let request = Paths.getLatestMedia(userID: userSession.user.id, parameters: parameters)
//            let response = try await userSession.client.send(request)
//
//            await MainActor.run {
//                hasRecentlyAdded = !response.value.isEmpty
//            }
//        }
//    }

    // MARK: Resume Items
    
    private func getResumeItems() async throws -> [BaseItemDto] {
        let resumeParameters = Paths.GetResumeItemsParameters(
            limit: 20,
            fields: ItemFields.minimumCases,
            enableUserData: true,
            includeItemTypes: [.movie, .episode]
        )

        let request = Paths.getResumeItems(userID: userSession.user.id, parameters: resumeParameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    func markItemUnplayed(_ item: BaseItemDto) {
        guard resumeItems.contains(where: { $0.id == item.id! }) else { return }

        Task {
            let request = Paths.markUnplayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
            let _ = try await userSession.client.send(request)

//            refreshResumeItems()
//            refreshHasNextUp()
        }
    }

    func markItemPlayed(_ item: BaseItemDto) {
        guard resumeItems.contains(where: { $0.id == item.id! }) else { return }

        Task {
            let request = Paths.markPlayedItem(
                userID: userSession.user.id,
                itemID: item.id!
            )
            let _ = try await userSession.client.send(request)

//            refreshResumeItems()
//            refreshHasNextUp()
        }
    }

    // MARK: Next Up Items

//    private func refreshHasNextUp() {
//        Task {
//            let parameters = Paths.GetNextUpParameters(
//                userID: userSession.user.id,
//                limit: 1
//            )
//            let request = Paths.getNextUp(parameters: parameters)
//            let response = try await userSession.client.send(request)
//
//            await MainActor.run {
//                hasNextUp = !(response.value.items?.isEmpty ?? true)
//            }
//        }
//    }
}
