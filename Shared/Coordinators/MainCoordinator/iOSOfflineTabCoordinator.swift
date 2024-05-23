//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class OfflineTabCoordinator: TabCoordinatable {

    var child = TabChild(startingItems: [\OfflineTabCoordinator.downloads])

    @Route(tabItem: makeDownloadsTab, onTapped: onDownloadsTapped)
    var downloads = makeDownloads

    func makeDownloads() -> NavigationViewCoordinator<DownloadListCoordinator> {
        NavigationViewCoordinator(DownloadListCoordinator())
    }

    func onDownloadsTapped(isRepeat: Bool, coordinator: NavigationViewCoordinator<DownloadListCoordinator>) {
        if isRepeat {
            coordinator.child.popToRoot()
        }
    }

    @ViewBuilder
    func makeDownloadsTab(isActive: Bool) -> some View {
        Image(systemName: "rectangle.stack.fill")
        L10n.downloads.text
    }

    @ViewBuilder
    func customize(_ view: AnyView) -> some View {
        view.onAppear {
            AppURLHandler.shared.appURLState = .allowed
            // TODO: todo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                AppURLHandler.shared.processLaunchedURLIfNeeded()
            }
        }
    }
}
