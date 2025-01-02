//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct StudiosHStack: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        let studios: [NameGuidPair]

        var body: some View {
            PillHStack(
                title: L10n.studios,
                items: studios
            ).onSelect { studio in
                let viewModel = ItemLibraryViewModel(parent: studio)
                router.route(to: \.library, viewModel)
            }
        }
    }
}
