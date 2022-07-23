//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class SettingsCoordinator: NavigationCoordinatable {
    let stack = NavigationStack(initial: \SettingsCoordinator.start)

    @Root
    var start = makeStart
    @Route(.push)
    var serverDetail = makeServerDetail
    @Route(.push)
    var overlaySettings = makeOverlaySettings
    @Route(.push)
    var experimentalSettings = makeExperimentalSettings
    @Route(.push)
    var customizeViewsSettings = makeCustomizeViewsSettings
    @Route(.push)
    var missingSettings = makeMissingSettings
    @Route(.push)
    var about = makeAbout

    #if !os(tvOS)
        @Route(.push)
        var quickConnect = makeQuickConnectSettings
        @Route(.push)
        var fontPicker = makeFontPicker
    #endif

    @ViewBuilder
    func makeServerDetail() -> some View {
        let viewModel = ServerDetailViewModel(server: SessionManager.main.currentLogin.server)
        ServerDetailView(viewModel: viewModel)
    }

    @ViewBuilder
    func makeOverlaySettings() -> some View {
        OverlaySettingsView()
    }

    @ViewBuilder
    func makeExperimentalSettings() -> some View {
        ExperimentalSettingsView()
    }

    @ViewBuilder
    func makeCustomizeViewsSettings() -> some View {
        CustomizeViewsSettings()
    }

    @ViewBuilder
    func makeMissingSettings() -> some View {
        MissingItemsSettingsView()
    }

    @ViewBuilder
    func makeAbout() -> some View {
        AboutView()
    }

    #if !os(tvOS)
        @ViewBuilder
        func makeQuickConnectSettings() -> some View {
            let viewModel = QuickConnectSettingsViewModel()
            QuickConnectSettingsView(viewModel: viewModel)
        }

        @ViewBuilder
        func makeFontPicker() -> some View {
            FontPickerView()
                .navigationTitle(L10n.subtitleFont)
        }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        let viewModel = SettingsViewModel(server: SessionManager.main.currentLogin.server, user: SessionManager.main.currentLogin.user)
        SettingsView(viewModel: viewModel)
    }
}
