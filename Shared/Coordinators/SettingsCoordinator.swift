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
    @Route(.push)
    var customizeViewsSettings = makeCustomizeViewsSettings
    @Route(.push)
    var experimentalSettings = makeExperimentalSettings
    @Route(.push)
    var serverDetail = makeServerDetail
    @Route(.push)
    var videoPlayerSettings = makeVideoPlayerSettings

    #if os(iOS)
    @Route(.push)
    var appIconSelector = makeAppIconSelector
    @Route(.push)
    var log = makeLog
    @Route(.push)
    var nativePlayerSettings = makeNativePlayerSettings
    @Route(.push)
    var quickConnect = makeQuickConnectSettings
    #endif
    
    #if os(tvOS)
    @Route(.modal)
    var appearanceSelector = makeAppearanceSelector
    #endif

    private let viewModel: SettingsViewModel

    init() {
        viewModel = .init()
    }

    @ViewBuilder
    func makeAbout() -> some View {
        AboutAppView(viewModel: viewModel)
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
    func makeServerDetail() -> some View {
        ServerDetailView(viewModel: .init(server: .sample))
    }

    func makeVideoPlayerSettings() -> VideoPlayerSettingsCoordinator {
        VideoPlayerSettingsCoordinator()
    }

    #if os(iOS)
    @ViewBuilder
    func makeAppIconSelector() -> some View {
        AppIconSelectorView(viewModel: viewModel)
    }

    @ViewBuilder
    func makeLog() -> some View {
        ConsoleView()
    }
    
    @ViewBuilder
    func makeNativePlayerSettings() -> some View {
        NativeVideoPlayerSettingsView()
    }
    
    @ViewBuilder
    func makeQuickConnectSettings() -> some View {
        QuickConnectSettingsView(viewModel: .init())
    }
    #endif

    #if os(tvOS)
    @ViewBuilder
    func makeAppearanceSelector() -> some View {
        NavigationView {
            AppAppearanceSelector()
        }
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        SettingsView(viewModel: viewModel)
    }
}
