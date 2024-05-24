//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import Factory
import Foundation
import Stinsen
import SwiftUI

final class DownloadListCoordinator: NavigationCoordinatable {
    @Injected(Container.downloadManager)
    private var downloadManager

    let stack = NavigationStack(initial: \DownloadListCoordinator.start)

    @Root
    var start = makeStart
    @Route(.modal)
    var downloadTask = makeDownloadTask

    func makeDownloadTask(downloadTask: DownloadEntity) -> NavigationViewCoordinator<DownloadTaskCoordinator> {
        NavigationViewCoordinator(DownloadTaskCoordinator(downloadTask: downloadTask))
    }

    @ViewBuilder
    private func makeStart() -> DownloadListView {
        DownloadListView(viewModel: .init(), downloadManager: downloadManager)
    }
}
#endif
