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
    var about = makeAbout
    @Route(.push)
    var customizeViewsSettings = makeCustomizeViewsSettings
    @Route(.push)
    var experimentalSettings = makeExperimentalSettings
    @Route(.push)
    var nativePlayerSettings = makeNativePlayerSettings
    @Route(.push)
    var serverDetail = makeServerDetail
    @Route(.push)
    var videoPlayerSettings = makeVideoPlayerSettings

    #if !os(tvOS)
    @Route(.push)
    var quickConnect = makeQuickConnectSettings
    #endif
    
    @ViewBuilder
    func makeAbout() -> some View {
        AboutAppView()
    }
    
    @ViewBuilder
    func makeCustomizeViewsSettings() -> some View {
        CustomizeViewsSettings()
    }
    
    @ViewBuilder
    func makeExperimentalSettings() -> some View {
        ExperimentalSettingsView()
    }
    
    @ViewBuilder
    func makeNativePlayerSettings() -> some View {
        NativeVideoPlayerSettingsView()
    }

    @ViewBuilder
    func makeServerDetail() -> some View {
        ServerDetailView(viewModel: .init(server: SessionManager.main.currentLogin.server))
    }

    func makeVideoPlayerSettings() -> VideoPlayerSettingsCoordinator {
        VideoPlayerSettingsCoordinator()
    }

    #if !os(tvOS)
    @ViewBuilder
    func makeQuickConnectSettings() -> some View {
        QuickConnectSettingsView(viewModel: .init())
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        let viewModel = SettingsViewModel(server: SessionManager.main.currentLogin.server, user: SessionManager.main.currentLogin.user)
        SettingsView(viewModel: viewModel)
    }
}
