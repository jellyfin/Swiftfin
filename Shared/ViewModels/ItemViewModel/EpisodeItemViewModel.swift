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

final class EpisodeItemViewModel: ItemViewModel {

    // MARK: - Published Episode Items

    @Published
    private(set) var seriesItem: BaseItemDto?

    // MARK: - Task

    private var seriesItemTask: AnyCancellable?
    private var toggleSeriesFavoriteTask: AnyCancellable?
    private var toggleSeriesWatchlistTask: AnyCancellable?
    private var toggleSeriesPlayedTask: AnyCancellable?

    #if os(tvOS)
    // The tvOS episode page never shows the EPISODE's own related content — its "More Like This" row
    // uses the SERIES' similar items, its trailer button uses the SERIES' trailers, and it renders no
    // special-features or additional-parts rows. Skip those episode-level fetches entirely (they were
    // pure waste — see SimpleItemContentView). The episode's own full item IS still fetched (it drives
    // the header, cast and About). iOS is unaffected.
    override var fetchesSimilarItems: Bool {
        false
    }

    override var fetchesExtras: Bool {
        false
    }
    #endif

    // MARK: - Override Response

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {

        switch action {
        case .refresh, .backgroundRefresh:
            seriesItemTask?.cancel()

            seriesItemTask = Task {
                let seriesItem = try await self.getSeriesItem()

                await MainActor.run {
                    self.seriesItem = seriesItem
                }
            }
            .asAnyCancellable()
        default: ()
        }

        return super.respond(to: action)
    }

    // MARK: - Get Series Items

    private func getSeriesItem() async throws -> BaseItemDto {

        guard let seriesID = item.seriesID else { throw ErrorMessage("Expected series ID missing") }

        // Use the full-item endpoint (rather than `getItems` + minimum fields) so the series carries
        // its `remoteTrailers` and complete `userData` — both needed to drive the episode page's
        // series-level favorite/watchlist and the series trailer button.
        let request = try Paths.getItem(itemID: seriesID, userID: authenticatedUser.id)
        let response = try await send(request)

        return response.value
    }

    // MARK: - Series-Level Toggles

    // On an episode page, favorite/watchlist act on the parent SERIES, not the single episode.
    // Each toggle optimistically updates the cached `seriesItem` and reverts on failure.

    func toggleSeriesIsFavorite() {
        guard let seriesID = seriesItem?.id else { return }

        toggleSeriesFavoriteTask?.cancel()
        let before = seriesItem?.userData?.isFavorite ?? false
        seriesItem?.userData?.isFavorite = !before

        toggleSeriesFavoriteTask = Task {
            do {
                try await setIsFavorite(!before, itemID: seriesID)
            } catch {
                await MainActor.run { self.seriesItem?.userData?.isFavorite = before }
            }
        }
        .asAnyCancellable()
    }

    func toggleSeriesIsInWatchlist() {
        guard let seriesID = seriesItem?.id else { return }

        toggleSeriesWatchlistTask?.cancel()
        let before = seriesItem?.userData?.isLikes ?? false
        seriesItem?.userData?.isLikes = !before

        toggleSeriesWatchlistTask = Task {
            do {
                try await setIsInWatchlist(!before, itemID: seriesID)
            } catch {
                await MainActor.run { self.seriesItem?.userData?.isLikes = before }
            }
        }
        .asAnyCancellable()
    }

    /// Unwatches the series and adds it to the watchlist in one step — used when the series is
    /// already watched and the user opts to re-add it from the episode page.
    func unwatchSeriesAndAddToWatchlist() {
        guard let seriesID = seriesItem?.id else { return }

        toggleSeriesPlayedTask?.cancel()
        let beforePlayed = seriesItem?.userData?.isPlayed ?? false
        let beforeLikes = seriesItem?.userData?.isLikes ?? false
        seriesItem?.userData?.isPlayed = false
        seriesItem?.userData?.isLikes = true

        toggleSeriesPlayedTask = Task {
            do {
                try await setIsPlayed(false, itemID: seriesID)
                try await setIsInWatchlist(true, itemID: seriesID)
            } catch {
                await MainActor.run {
                    self.seriesItem?.userData?.isPlayed = beforePlayed
                    self.seriesItem?.userData?.isLikes = beforeLikes
                }
            }
        }
        .asAnyCancellable()
    }
}
