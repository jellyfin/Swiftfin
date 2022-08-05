//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import Stinsen

final class EpisodeItemViewModel: ItemViewModel {

    @RouterObject
    private var itemRouter: ItemCoordinator.Router?
    @Published
    var playButtonText: String = ""
    @Published
    var mediaDetailItems: [[BaseItemDto.ItemDetail]] = []

    override init(item: BaseItemDto) {
        super.init(item: item)

        $videoPlayerViewModels.sink(receiveValue: { newValue in
            self.mediaDetailItems = self.createMediaDetailItems(viewModels: newValue)
        })
        .store(in: &cancellables)
    }

    override func updateItem() {
        ItemsAPI.getItems(
            userId: SessionManager.main.currentLogin.user.id,
            limit: 1,
            fields: [
                .primaryImageAspectRatio,
                .seriesPrimaryImage,
                .seasonUserData,
                .overview,
                .genres,
                .people,
                .chapters,
            ],
            enableUserData: true,
            ids: [item.id ?? ""]
        )
        .sink { completion in
            self.handleAPIRequestError(completion: completion)
        } receiveValue: { response in
            if let item = response.items?.first {
                self.item = item
                self.playButtonItem = item
            }
        }
        .store(in: &cancellables)
    }

    private func createMediaDetailItems(viewModels: [VideoPlayerViewModel]) -> [[BaseItemDto.ItemDetail]] {
        var fileMediaItems: [[BaseItemDto.ItemDetail]] = []

        for viewModel in viewModels {

            let audioStreams = viewModel.audioStreams.compactMap { "\($0.displayTitle ?? L10n.noTitle) (\($0.codec ?? L10n.noCodec))" }
                .joined(separator: ", ")

            let subtitleStreams = viewModel.subtitleStreams
                .compactMap { "\($0.displayTitle ?? L10n.noTitle) (\($0.codec ?? L10n.noCodec))" }
                .joined(separator: ", ")

            let currentMediaItems: [BaseItemDto.ItemDetail] = [
                .init(title: "File", content: viewModel.filename ?? "--"),
                .init(title: "Audio", content: audioStreams),
                .init(title: "Subtitles", content: subtitleStreams),
            ]

            fileMediaItems.append(currentMediaItems)
        }

        //        print(fileMediaItems)

        return fileMediaItems
    }
}
