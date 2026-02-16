//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import SwiftUIIntrospect

extension View {

    @ViewBuilder
    func navigationBarBranding(
        isLoading: Bool = false
    ) -> some View {
        modifier(
            NavigationBarBrandingModifier(
                isLoading: isLoading
            )
        )
    }

    /// - Important: This does nothing on tvOS.
    @ViewBuilder
    func navigationBarTitleDisplayMode(_ mode: NavigationBarItem.TitleDisplayMode) -> some View {
        self
    }

    /// - Important: This does nothing on tvOS.
    @ViewBuilder
    func statusBarHidden() -> some View {
        self
    }

    /// - Important: This does nothing on tvOS.
    @ViewBuilder
    func prefersStatusBarHidden(_ hidden: Bool) -> some View {
        self
    }
}

extension EnvironmentValues {

    @Entry
    var presentationCoordinator: PresentationCoordinator = .init()
}

struct PresentationCoordinator {
    var isPresented: Bool = false
}
