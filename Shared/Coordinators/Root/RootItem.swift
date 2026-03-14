//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
struct RootItem: Identifiable {

    var id: String
    let content: AnyView

    init(
        id: String,
        @ViewBuilder content: () -> some View
    ) {
        self.id = id
        self.content = AnyView(content())
    }

    static let appLoading = RootItem(id: "appLoading") {
        NavigationInjectionView(coordinator: .init()) {
            AppLoadingView()
        }
    }

    static let mainTab = RootItem(id: "mainTab") {
        MainTabView()
    }

    static let selectUser = RootItem(id: "selectUser") {
        NavigationInjectionView(coordinator: .init()) {
            SelectUserView()
        }
    }

    #if os(iOS)
    static let serverCheck = RootItem(id: "serverCheck") {
        NavigationInjectionView(coordinator: .init()) {
            ServerCheckView()
        }
    }
    #endif
}
