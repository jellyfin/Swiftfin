//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import PulseUI
import Stinsen
import SwiftUI

final class AppSettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \AppSettingsCoordinator.start)

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

    @Route(.fullScreen)
    var hourPicker = makeHourPicker
    #endif

    init() {}

    #if os(iOS)
    @ViewBuilder
    func makeAbout(viewModel: SettingsViewModel) -> some View {
        AboutAppView(viewModel: viewModel)
    }

    @ViewBuilder
    func makeAppIconSelector(viewModel: SettingsViewModel) -> some View {
        AppIconSelectorView(viewModel: viewModel)
    }
    #endif

    @ViewBuilder
    func makeLog() -> some View {
        ConsoleView()
    }

    @ViewBuilder
    func makeStart() -> some View {
        AppSettingsView()
    }

    #if os(tvOS)
    @ViewBuilder
    func makeHourPicker() -> some View {
        ZStack {
            BlurView()
                .ignoresSafeArea()

            HourMinutePicker()
        }
    }
    #endif
}
