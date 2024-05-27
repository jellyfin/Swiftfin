//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class OfflineItemCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \OfflineItemCoordinator.start)

    @Root
    var start = makeStart
    @Route(.push)
    var item = makeItem
    @Route(.push)
    var library = makeLibrary

    @Route(.modal)
    var itemOverview = makeItemOverview
    @Route(.modal)
    var mediaSourceInfo = makeMediaSourceInfo
    @Route(.modal)
    var downloadTask = makeDownloadTask

    private let itemDto: BaseItemDto
    private let viewModel: OfflineViewModel

    init(item: BaseItemDto, viewModel: OfflineViewModel) {
        self.itemDto = item
        self.viewModel = viewModel
    }

    func makeItem(item: BaseItemDto) -> OfflineItemCoordinator {
        OfflineItemCoordinator(item: item, viewModel: viewModel)
    }

    func makeLibrary(viewModel: PagingLibraryViewModel<BaseItemDto>) -> OfflineLibraryCoordinator<BaseItemDto> {
        OfflineLibraryCoordinator(viewModel: viewModel, offlineViewModel: self.viewModel)
    }

    func makeItemOverview(item: BaseItemDto) -> NavigationViewCoordinator<BasicNavigationViewCoordinator> {
        NavigationViewCoordinator {
            ItemOverviewView(item: item)
        }
    }

    func makeMediaSourceInfo(source: MediaSourceInfo) -> NavigationViewCoordinator<MediaSourceInfoCoordinator> {
        NavigationViewCoordinator(MediaSourceInfoCoordinator(mediaSourceInfo: source))
    }

    func makeDownloadTask(downloadTask: DownloadEntity) -> NavigationViewCoordinator<DownloadTaskCoordinator> {
        NavigationViewCoordinator(DownloadTaskCoordinator(downloadTask: downloadTask))
    }

    @ViewBuilder
    func makeStart() -> some View {
        OfflineItemView(item: itemDto, offlineModel: viewModel)
    }
}
