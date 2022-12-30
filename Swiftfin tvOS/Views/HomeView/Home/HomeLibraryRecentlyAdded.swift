//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import JellyfinAPI

extension HomeView {
    struct HomeLibraryRecentlyAdded: View {
        @EnvironmentObject private var router: HomeCoordinator.Router
        @ObservedObject public var viewModel: LibraryViewModel
        
        public let focusedImage: FocusState<String?>.Binding
        
        var body: some View {
            Group {
                HomeSectionText(title: L10n.latestWithString(viewModel.parent?.displayName ?? .emptyDash)) {
                    router.route(to: \.library, viewModel.libraryCoordinatorParameters)
                }
                HomeItemRow(items: viewModel.items, size: .five, focusPrefix: "nextup", focusedImage: focusedImage)
            }
        }
    }
}
