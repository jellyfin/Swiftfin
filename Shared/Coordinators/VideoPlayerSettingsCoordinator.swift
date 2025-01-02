//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

final class VideoPlayerSettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \VideoPlayerSettingsCoordinator.start)

    @Root
    var start = makeStart
    @Route(.push)
    var fontPicker = makeFontPicker

    #if os(iOS)
    @Route(.push)
    var gestureSettings = makeGestureSettings
    @Route(.push)
    var actionButtonSelector = makeActionButtonSelector
    #endif

    func makeFontPicker(selection: Binding<String>) -> some View {
        FontPickerView(selection: selection)
    }

    #if os(iOS)

    @ViewBuilder
    func makeGestureSettings() -> some View {
        GestureSettingsView()
    }

    func makeActionButtonSelector(selectedButtonsBinding: Binding<[VideoPlayerActionButton]>) -> some View {
        ActionButtonSelectorView(selection: selectedButtonsBinding)
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        VideoPlayerSettingsView()
    }
}
