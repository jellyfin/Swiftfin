//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

// Since we don't view care to view seasons directly, this doesn't subclass from `ItemViewModel`.
// If we ever care for viewing seasons directly, subclass from that and have the library view model
// as a property.
final class SeasonItemViewModel: PagingLibraryViewModel<BaseItemDto>, Identifiable {

    let season: BaseItemDto

    var id: String? {
        season.id
    }

    init(season: BaseItemDto) {
        self.season = season
        super.init(parent: season)

        // Keep episode cards' watched state live WITHOUT reloading the list (which would flicker
        // the carousel). When an episode's own metadata changes, patch just that card; when the
        // parent series is (un)watched, reflect it on every loaded episode.
        Notifications[.itemMetadataDidChange]
            .publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] newItem in
                guard let self else { return }

                let key = newItem.unwrappedIDHashOrZero

                if let existing = self.elements[id: key] {
                    // One episode's metadata changed — patch only if it actually differs, so an
                    // unchanged refresh (e.g. the series' own load) doesn't reload the cell.
                    if existing != newItem {
                        self.elements[id: key] = newItem
                    }
                } else if let newID = newItem.id,
                          newID == self.season.seriesID,
                          let seriesPlayed = newItem.userData?.isPlayed
                {
                    // The parent series was (un)watched — reflect it on every loaded episode, but
                    // mutate ONLY the episodes whose state actually changes. This is critical: the
                    // series posts this notification on every load with no real change, and a blind
                    // reassignment would reload the whole episode CollectionHStack (wrong-poster
                    // flash + reposition) and re-render the background blur.
                    for elementKey in self.elements.ids
                        where (self.elements[id: elementKey]?.userData?.isPlayed ?? false) != seriesPlayed
                    {
                        self.elements[id: elementKey]?.userData?.isPlayed = seriesPlayed
                        if seriesPlayed {
                            self.elements[id: elementKey]?.userData?.playbackPositionTicks = 0
                        }
                    }
                }
            }
            .store(in: &cancellables)

        // Live user-data push (WebSocket → `UserDataSocketObserver`): when an episode in THIS season is
        // (un)watched / (un)liked / its progress changes on the server (incl. from another client or by
        // marking the whole season watched on the web), patch just that episode card's `userData` in
        // place. This is the path that makes show/season pages update — episodes have no `ItemViewModel`,
        // so the metadata-refetch route above never reaches them.
        Notifications[.itemUserDataDidChange]
            .publisher
            .receive(on: RunLoop.main)
            .sink { [weak self] userData in
                guard let self, let itemID = userData.itemID else { return }

                let key = itemID.hashValue // matches `unwrappedIDHashOrZero`, the element id
                guard let existing = self.elements[id: key], existing.userData != userData else { return }
                self.elements[id: key]?.userData = userData
            }
            .store(in: &cancellables)
    }

    override func get(page: Int) async throws -> [BaseItemDto] {
        guard let parentID = parent?.id else { return [] }

        var parameters = Paths.GetEpisodesParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        // Only ever render episodes that ACTUALLY EXIST on the server. `isMissing` is a FILTER, not a toggle:
        // `false` excludes missing/unaired episodes entirely. We hardcode this — ignoring the account's
        // "Display Missing Episodes" setting — ON PURPOSE for now: honoring that setting surfaced placeholder
        // cards for missing episodes that glitched the season's episode layout (and `isMissing == true` even
        // hid the real episodes — see the bug this replaced). Deferred until missing-episode rendering is built
        // properly; until then every server shows a clean present-only list, and it's on the user to keep their
        // library complete / track what they watch.
        parameters.isMissing = false
        parameters.seasonID = parentID

//        parameters.startIndex = page * pageSize
//        parameters.limit = pageSize

        let request = Paths.getEpisodes(
            seriesID: parentID,
            parameters: parameters
        )
        let response = try await send(request)

        return response.value.items ?? []
    }
}
