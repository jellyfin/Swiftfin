//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import PulseUI
import Stinsen
import SwiftUI

final class BasicAppSettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \BasicAppSettingsCoordinator.start)

    @Root
    var start = makeStart

    #if os(iOS)
    @Route(.push)
    var about = makeAbout
    @Route(.push)
    var appIconSelector = makeAppIconSelector
    @Route(.push)
    var log = makeLog
    #endif

    #if os(tvOS)
    @Route(.modal)
    var log = makeLog
    #endif

    private let viewModel: SettingsViewModel

    init() {
        viewModel = .init()
    }

    #if os(iOS)
    @ViewBuilder
    func makeAbout() -> some View {
        AboutAppView(viewModel: viewModel)
    }

    @ViewBuilder
    func makeAppIconSelector() -> some View {
        AppIconSelectorView(viewModel: viewModel)
    }
    #endif

    @ViewBuilder
    func makeLog() -> some View {
        ConsoleView()
    }

    @ViewBuilder
    func makeStart() -> some View {
        BasicAppSettingsView(viewModel: viewModel)
    }
}
