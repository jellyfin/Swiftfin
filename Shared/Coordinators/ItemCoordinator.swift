//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class ItemCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \ItemCoordinator.start)

    @Root
    var start = makeStart
    @Route(.push)
    var item = makeItem
    @Route(.push)
    var basicLibrary = makeBasicLibrary
    @Route(.push)
    var library = makeLibrary
    @Route(.push)
    var castAndCrew = makeCastAndCrew
    @Route(.modal)
    var itemOverview = makeItemOverview

    #if os(iOS)
    @Route(.modal)
    var mediaSourceInfo = makeMediaSourceInfo
    @Route(.modal)
    var downloadTask = makeDownloadTask
    #endif

    #if os(tvOS)
    @Route(.fullScreen)
    var videoPlayer = makeVideoPlayer
    #endif

    let itemDto: BaseItemDto

    init(item: BaseItemDto) {
        self.itemDto = item
    }

    func makeItem(item: BaseItemDto) -> ItemCoordinator {
        ItemCoordinator(item: item)
    }

    func makeBasicLibrary(parameters: BasicLibraryCoordinator.Parameters) -> BasicLibraryCoordinator {
        BasicLibraryCoordinator(parameters: parameters)
    }

    func makeLibrary(parameters: LibraryCoordinator.Parameters) -> LibraryCoordinator {
        LibraryCoordinator(parameters: parameters)
    }

    func makeCastAndCrew(people: [BaseItemPerson]) -> CastAndCrewLibraryCoordinator {
        CastAndCrewLibraryCoordinator(people: people)
    }

    func makeItemOverview(item: BaseItemDto) -> NavigationViewCoordinator<ItemOverviewCoordinator> {
        NavigationViewCoordinator(ItemOverviewCoordinator(item: itemDto))
    }

    #if os(iOS)
    func makeMediaSourceInfo(mediaSourceInfo: MediaSourceInfo) -> NavigationViewCoordinator<MediaSourceInfoCoordinator> {
        NavigationViewCoordinator(MediaSourceInfoCoordinator(mediaSourceInfo: mediaSourceInfo))
    }

    func makeDownloadTask(downloadTask: DownloadTask) -> NavigationViewCoordinator<DownloadTaskCoordinator> {
        NavigationViewCoordinator(DownloadTaskCoordinator(downloadTask: downloadTask))
    }
    #endif

    #if os(tvOS)
    func makeVideoPlayer(manager: VideoPlayerManager) -> NavigationViewCoordinator<VideoPlayerCoordinator> {
        NavigationViewCoordinator(VideoPlayerCoordinator(manager: manager))
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        ItemView(item: itemDto)
    }
}
