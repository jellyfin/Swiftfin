//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import Stinsen

final class OfflineEpisodeItemViewModel: OfflineItemViewModel {

    // can we not inject it everywhere
    @Injected(Container.downloadManager)
    private var downloadManager

    @Published
    private(set) var seriesItem: BaseItemDto?

    private var seriesItemTask: AnyCancellable?

    override init(item: BaseItemDto) {
        super.init(item: item)

        $lastAction
            .sink { [weak self] action in
                guard let self else { return }

                if action == .refresh {
                    seriesItemTask?.cancel()

                    seriesItemTask = Task {
                        let seriesItem = try await self.getSeriesItem()

                        await MainActor.run {
                            self.seriesItem = seriesItem
                        }
                    }
                    .asAnyCancellable()
                }
            }
            .store(in: &cancellables)
    }

    private func getSeriesItem() async throws -> BaseItemDto {

        guard let seriesID = item.seriesID else { throw JellyfinAPIError("Expected series ID missing") }
        guard let downloadEntity = (downloadManager.downloads.first { download in download.item.id == item.id })
        else { throw JellyfinAPIError("Expected download entity missing") }

        guard let seriesItem = downloadEntity.seriesItem else { throw JellyfinAPIError("Expected missing series item") }

        return seriesItem
    }
}
