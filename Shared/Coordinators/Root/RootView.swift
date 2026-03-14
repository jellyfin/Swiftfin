//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import Transmission

// Status bar presentation needs to happen at this level
struct RootView: View {

    @State
    private var isStatusBarHidden: Bool = false

    @StateObject
    private var rootCoordinator: RootCoordinator = .init()

    var body: some View {
        ZStack {
            if rootCoordinator.root.id == RootItem.appLoading.id {
                RootItem.appLoading.content
            }

            if rootCoordinator.root.id == RootItem.mainTab.id {
                RootItem.mainTab.content
            }

            if rootCoordinator.root.id == RootItem.selectUser.id {
                RootItem.selectUser.content
            }

            #if os(iOS)
            if rootCoordinator.root.id == RootItem.serverCheck.id {
                RootItem.serverCheck.content
            }
            #endif
        }
        .animation(.linear(duration: 0.1), value: rootCoordinator.root.id)
        .environmentObject(rootCoordinator)
        .prefersStatusBarHidden(isStatusBarHidden)
        .onPreferenceChange(IsStatusBarHiddenKey.self) { newValue in
            isStatusBarHidden = newValue
        }
    }
}
