//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

private struct ContentGroupRefreshModifier<Provider: ContentGroupProvider>: ViewModifier {
    @Environment(\.scenePhase)
    private var scenePhase

    @State
    private var isVisible = false

    let viewModel: ContentGroupViewModel<Provider>

    func body(content: Content) -> some View {
        content
            .onAppear {
                isVisible = true
                viewModel.setIsActive(scenePhase == .active)
            }
            .onDisappear {
                isVisible = false
                viewModel.setIsActive(false)
            }
            .onChange(of: scenePhase) { _, phase in
                viewModel.setIsActive(isVisible && phase == .active)
            }
    }
}

extension View {
    func refreshingContentGroups(viewModel: ContentGroupViewModel<some ContentGroupProvider>) -> some View {
        modifier(ContentGroupRefreshModifier(viewModel: viewModel))
    }
}
