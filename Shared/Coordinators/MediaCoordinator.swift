//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class MediaCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \MediaCoordinator.start)

    @Root
    var start = makeStart
    #if os(tvOS)
    @Route(.modal)
    var library = makeLibrary
    #else
    @Route(.push)
    var library = makeLibrary
    @Route(.push)
    var liveTV = makeLiveTV
    @Route(.push)
    var downloads = makeDownloads
    #endif

    #if os(tvOS)
    func makeLibrary(parameters: LibraryCoordinator.Parameters) -> NavigationViewCoordinator<LibraryCoordinator> {
        NavigationViewCoordinator(LibraryCoordinator(parameters: parameters))
    }

    #else
    func makeLibrary(parameters: LibraryCoordinator.Parameters) -> LibraryCoordinator {
        LibraryCoordinator(parameters: parameters)
    }

    func makeLiveTV() -> LiveTVCoordinator {
        LiveTVCoordinator()
    }

    func makeDownloads() -> DownloadListCoordinator {
        DownloadListCoordinator()
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        MediaView(viewModel: .init())
    }
}
