//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class MediaCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \MediaCoordinator.start)

    @Root
    var start = makeStart
    #if os(tvOS)
    @Route(.modal)
    var library = makeLibrary
    @Route(.modal)
    var liveTV = makeLiveTV
    #else
    @Route(.push)
    var library = makeLibrary
    @Route(.push)
    var liveTV = makeLiveTV
    @Route(.push)
    var downloads = makeDownloads
    #endif

    #if os(tvOS)
    func makeLibrary(viewModel: PagingLibraryViewModel<BaseItemDto>) -> NavigationViewCoordinator<LibraryCoordinator<BaseItemDto>> {
        NavigationViewCoordinator(LibraryCoordinator(viewModel: viewModel))
    }
    #else
    func makeLibrary(viewModel: PagingLibraryViewModel<BaseItemDto>) -> LibraryCoordinator<BaseItemDto> {
        LibraryCoordinator(viewModel: viewModel)
    }

    func makeDownloads() -> DownloadListCoordinator {
        DownloadListCoordinator()
    }
    #endif

    func makeLiveTV() -> LiveTVCoordinator {
        LiveTVCoordinator()
    }

    @ViewBuilder
    func makeStart() -> some View {
        MediaView()
    }
}
