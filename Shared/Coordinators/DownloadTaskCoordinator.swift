//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import Foundation
import Stinsen
import SwiftUI

final class DownloadTaskCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \DownloadTaskCoordinator.start)

    @Root
    var start = makeStart

    let downloadTask: DownloadTask

    init(downloadTask: DownloadTask) {
        self.downloadTask = downloadTask
    }

    @ViewBuilder
    private func makeStart() -> DownloadTaskView {
        DownloadTaskView(downloadTask: downloadTask)
    }
}
#endif
