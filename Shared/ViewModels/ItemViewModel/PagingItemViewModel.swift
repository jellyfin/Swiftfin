//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

class PagingContentItemViewModel<ContentViewModel: PagingLibraryViewModel<BaseItemDto>>: ItemViewModel {

    // MARK: - Paging Library

    @Published
    private(set) var contents: ContentViewModel

    // MARK: - Task

    private var pagingContentsTask: AnyCancellable?

    init(item: BaseItemDto, contents: ContentViewModel) {
        self.contents = contents
        super.init(item: item)

        contents.$elements
            .map { elements in
                elements.first { $0.userData?.isPlayed == false } ?? elements.first
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPlayButtonItem in
                self?.playButtonItem = newPlayButtonItem
            }
            .store(in: &cancellables)
    }

    // MARK: - Override Response

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {
        switch action {
        case .backgroundRefresh, .refresh:
            pagingContentsTask?.cancel()

            pagingContentsTask = Task { [weak self] in
                guard let self else { return }

                await MainActor.run {
                    self.contents.send(.refresh)
                }
            }
            .asAnyCancellable()

            return super.respond(to: action)
        default:
            return super.respond(to: action)
        }
    }
}
