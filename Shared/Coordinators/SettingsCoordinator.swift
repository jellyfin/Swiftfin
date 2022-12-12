//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Files
import Foundation
import PulseUI
import Stinsen
import SwiftUI

final class SettingsCoordinator: NavigationCoordinatable {
    
    let stack = NavigationStack(initial: \SettingsCoordinator.start)

    @Root
    var start = makeStart
    
    @Route(.push)
    var about = makeAbout
    #if !os(tvOS)
    @Route(.push)
    var appIconSelector = makeAppIconSelector
    #endif
    @Route(.push)
    var customizeViewsSettings = makeCustomizeViewsSettings
    @Route(.push)
    var experimentalSettings = makeExperimentalSettings
    #if !os(tvOS)
    @Route(.push)
    var nativePlayerSettings = makeNativePlayerSettings
    #endif
    @Route(.push)
    var serverDetail = makeServerDetail
    @Route(.push)
    var videoPlayerSettings = makeVideoPlayerSettings

    #if !os(tvOS)
    @Route(.push)
    var quickConnect = makeQuickConnectSettings
    @Route(.push)
    var log = makeLog
    @Route(.modal)
    var shareFile = makeShareFile
    #endif
    
    private let viewModel: SettingsViewModel
    
    init() {
//        viewModel = .init(server: SessionManager.main.currentLogin.server, user: SessionManager.main.currentLogin.user)
        viewModel = .init(server: .sample, user: .sample)
    }
    
    @ViewBuilder
    func makeAbout() -> some View {
        AboutAppView(viewModel: viewModel)
    }
    
    #if !os(tvOS)
    @ViewBuilder
    func makeAppIconSelector() -> some View {
        AppIconSelectorView(viewModel: viewModel)
    }
    #endif
    
    @ViewBuilder
    func makeCustomizeViewsSettings() -> some View {
        CustomizeViewsSettings()
    }
    
    @ViewBuilder
    func makeExperimentalSettings() -> some View {
        ExperimentalSettingsView()
    }
    
    #if !os(tvOS)
    @ViewBuilder
    func makeNativePlayerSettings() -> some View {
        NativeVideoPlayerSettingsView()
    }
    #endif

    @ViewBuilder
    func makeServerDetail() -> some View {
//        ServerDetailView(viewModel: .init(server: SessionManager.main.currentLogin.server))
        Text("")
    }

    func makeVideoPlayerSettings() -> VideoPlayerSettingsCoordinator {
        VideoPlayerSettingsCoordinator()
    }

    #if !os(tvOS)
    @ViewBuilder
    func makeQuickConnectSettings() -> some View {
        QuickConnectSettingsView(viewModel: .init())
    }
    
    @ViewBuilder
    func makeLog() -> some View {
        ConsoleView()
    }
    
    @ViewBuilder
    func makeShareFile(file: File) -> some View {
        ActivityView(file: file)
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        SettingsView(viewModel: viewModel)
    }
}
