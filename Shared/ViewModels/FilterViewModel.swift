//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

@MainActor
@Stateful
final class FilterViewModel: ViewModel {

    @CasePathable
    enum Action {
        case cancel
        case getQueryFilters(isDownloads: Bool)
        case reset(filterType: ItemFilterType?)

        var transition: Transition {
            switch self {
            case .cancel, .reset: .none
            case .getQueryFilters:
                .background(.retrievingQueryFilters)
            }
        }
    }

    enum BackgroundState {
        case retrievingQueryFilters
    }

    @Published
    private(set) var allFilters: ItemFilterCollection = .all
    @Published
    var currentFilters: ItemFilterCollection

    private let parent: (any LibraryParent)?

    init(
        parent: (any LibraryParent)? = nil,
        currentFilters: ItemFilterCollection = .default
    ) {
        self.parent = parent
        self.currentFilters = currentFilters

        super.init()
    }

    func isFilterSelected(type: ItemFilterType) -> Bool {
        type.group
            .map(\.keyPath)
            .contains { keyPath in
                currentFilters[keyPath: keyPath] != ItemFilterCollection.default[keyPath: keyPath]
            }
    }

    @Function(\Action.Cases.reset)
    private func resetCurrentFilters(_ type: ItemFilterType?) {

        guard let type else {
            currentFilters = .default
            return
        }

        switch type {
        case .genres:
            currentFilters.genres = ItemFilterCollection.default.genres
        case .letter:
            currentFilters.letter = ItemFilterCollection.default.letter
        case .sortBy:
            currentFilters.sortBy = ItemFilterCollection.default.sortBy
            currentFilters.sortOrder = ItemFilterCollection.default.sortOrder
        case .tags:
            currentFilters.tags = ItemFilterCollection.default.tags
        case .traits:
            currentFilters.traits = ItemFilterCollection.default.traits
        case .years:
            currentFilters.years = ItemFilterCollection.default.years
        }
    }

    @Function(\Action.Cases.getQueryFilters)
    private func _getQueryFilters(_ isDownloads: Bool) async throws {
        if isDownloads {
            try await getLocalQueryFilters()
        } else {
            try await getServerQueryFilters()
        }
    }

    private func getServerQueryFilters() async throws {
        let parameters = Paths.GetQueryFiltersLegacyParameters(
            userID: userSession.user.id,
            parentID: parent?.id
        )

        let request = Paths.getQueryFiltersLegacy(parameters: parameters)
        let response = try await userSession.client.send(request)

        let genres: [ItemGenre] = (response.value.genres ?? [])
            .map(ItemGenre.init)

        let tags = (response.value.tags ?? [])
            .map(ItemTag.init)

        // Manually sort so that most recent years are "first"
        let years = (response.value.years ?? [])
            .sorted(by: >)
            .map(ItemYear.init)

        allFilters.genres = genres
        allFilters.tags = tags
        allFilters.years = years
    }

    private func getLocalQueryFilters() async throws {
        let manager = Container.shared.downloadManager()

        var genreSet = Set<String>()
        var tagSet = Set<String>()
        var yearSet = Set<Int>()

        for item in manager.tasks where item.isCompleted {
            if let genres = item.item.genres {
                genreSet.formUnion(genres)
            }
            if let tags = item.item.tags {
                tagSet.formUnion(tags)
            }
            if let year = item.item.productionYear {
                yearSet.insert(year)
            }
        }

        allFilters.genres = genreSet.sorted().map {
            ItemGenre(from: .init(displayTitle: $0, value: $0))
        }

        allFilters.tags = tagSet.sorted().map {
            ItemTag(from: .init(displayTitle: $0, value: $0))
        }

        allFilters.years = yearSet.sorted(by: >).map { year in
            ItemYear(from: .init(displayTitle: "\(year)", value: "\(year)"))
        }
    }
}
