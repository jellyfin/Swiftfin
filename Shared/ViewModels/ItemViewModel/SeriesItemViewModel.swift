//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import IdentifiedCollections
import JellyfinAPI

// TODO: care for one long episodes list?
//       - after SeasonItemViewModel is bidirectional
//       - would have to see if server returns right amount of episodes/season
final class SeriesItemViewModel: ItemViewModel {

    @Published
    var seasons: IdentifiedArrayOf<SeasonItemViewModel> = []

    /// When set (e.g. the series is hosted inside an episode page), this episode is used as the
    /// `playButtonItem` instead of the series' next-up item — so the season/episode selector
    /// preselects and focuses *this* episode rather than next-up.
    private let preferredPlayButtonItem: BaseItemDto?

    // MARK: - Task

    private var seriesItemTask: AnyCancellable?

    @MainActor
    init(item: BaseItemDto, preferredPlayButtonItem: BaseItemDto? = nil) {
        self.preferredPlayButtonItem = preferredPlayButtonItem
        super.init(item: item)
    }

    // Defining a designated init above stops the superclass's `init(episode:)` from being
    // inherited, so re-declare it (mirrors `ItemViewModel.init(episode:)`).
    @MainActor
    convenience init(episode: BaseItemDto) {
        let shellSeriesItem = BaseItemDto(id: episode.seriesID, name: episode.seriesName)
        self.init(item: shellSeriesItem)
    }

    // MARK: - Episode-hosted lite load

    /// True when this series view model is embedded in the tvOS episode page (the only caller that
    /// passes `preferredPlayButtonItem`). In that case the page shows ONLY the season/episode selector
    /// and the series' "More Like This" row, and it was already handed the full series item — so the
    /// redundant full-item re-fetch, the extras (special features / trailers / parts) and the
    /// next-up/resume/first-available lookups (the play item is forced to the hosting episode) are all
    /// pure waste and skipped. Always `false` on iOS, so the iOS series page is completely unaffected.
    private var isEpisodeHosted: Bool {
        #if os(tvOS)
        preferredPlayButtonItem != nil
        #else
        false
        #endif
    }

    // Skip the redundant full series re-fetch (already in hand) and the extras the episode page never
    // shows. "More Like This" (similar items) is still fetched — it IS shown on the episode page.
    override var fetchesFullItem: Bool {
        !isEpisodeHosted
    }

    override var fetchesExtras: Bool {
        !isEpisodeHosted
    }

    // MARK: - Override Response

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {

        switch action {
        case .backgroundRefresh, .refresh:

            seriesItemTask?.cancel()

            Task { [weak self] in
                guard let self else { return }

                do {
                    async let nextUp = getNextUp()
                    async let resume = getResumeItem()
                    async let firstAvailable = getFirstAvailableItem()
                    async let seasons = getSeasons()

                    let newSeasons = try await seasons
                        .sorted { ($0.indexNumber ?? -1) < ($1.indexNumber ?? -1) }
                        .map(SeasonItemViewModel.init)

                    // Await all candidates so the structured-concurrency tasks complete, then pick
                    // the play-button item (preferred episode wins on an episode-hosted series).
                    let nextOrResume = try await [nextUp, resume].compacted().first
                    let firstAvailableItem = try await firstAvailable

                    await MainActor.run {
                        // Only replace the seasons when the set actually changes (by id). A
                        // background refresh fired by a favorite/watchlist/played toggle has the
                        // same seasons, so skipping reassignment avoids the carousel flickering
                        // (clearing to empty then repopulating). We never `removeAll()` first.
                        if self.seasons.map(\.id) != newSeasons.map(\.id) {
                            self.seasons = IdentifiedArrayOf(uniqueElements: newSeasons)
                        }

                        if let preferredPlayButtonItem = self.preferredPlayButtonItem {
                            self.playButtonItem = preferredPlayButtonItem
                        } else if let episodeItem = nextOrResume {
                            self.playButtonItem = episodeItem
                        } else if let firstAvailableItem {
                            self.playButtonItem = firstAvailableItem
                        }
                    }
                }
            }
            .store(in: &cancellables)
        default: ()
        }

        return super.respond(to: action)
    }

    // MARK: - Get Next Up Item

    private func getNextUp() async throws -> BaseItemDto? {
        // The hosting episode is the play item — next-up isn't needed.
        guard !isEpisodeHosted else { return nil }

        var parameters = Paths.GetNextUpParameters()
        parameters.fields = .MinimumFields
        parameters.seriesID = item.id

        let request = Paths.getNextUp(parameters: parameters)
        let response = try await send(request)

        guard let item = response.value.items?.first, !item.isMissing else {
            return nil
        }

        return item
    }

    // MARK: - Get Resumable Item

    private func getResumeItem() async throws -> BaseItemDto? {
        // The hosting episode is the play item — resume lookup isn't needed.
        guard !isEpisodeHosted else { return nil }

        var parameters = Paths.GetResumeItemsParameters()
        parameters.fields = .MinimumFields
        parameters.limit = 1
        parameters.parentID = item.id

        let request = Paths.getResumeItems(parameters: parameters)
        let response = try await send(request)

        return response.value.items?.first
    }

    // MARK: - Get First Available Item

    private func getFirstAvailableItem() async throws -> BaseItemDto? {
        // The hosting episode is the play item — the first-available fallback isn't needed.
        guard !isEpisodeHosted else { return nil }

        var parameters = Paths.GetItemsParameters()
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = [.episode]
        parameters.isRecursive = true
        parameters.limit = 1
        parameters.parentID = item.id
        parameters.sortOrder = [.ascending]

        let request = Paths.getItems(parameters: parameters)
        let response = try await send(request)

        return response.value.items?.first
    }

    // MARK: - Get First Item Seasons

    private func getSeasons() async throws -> [BaseItemDto] {
        guard let itemID = item.id else { return [] }

        var parameters = Paths.GetSeasonsParameters()
        parameters.isMissing = Defaults[.Customization.shouldShowMissingSeasons] ? nil : false

        let request = Paths.getSeasons(
            seriesID: itemID,
            parameters: parameters
        )
        let response = try await send(request)

        return response.value.items ?? []
    }
}
