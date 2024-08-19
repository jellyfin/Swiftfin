//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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
    @Route(.push)
    var actionButtonSelector = makeActionButtonSelector

    #if os(tvOS)
    @Route(.push)
    var resumeOffset = makeResumeOffset
    @Route(.push)
    var subtitleSize = makeSubtitleSize
    #elseif os(iOS)
    @Route(.push)
    var gestureSettings = makeGestureSettings
    #endif

    func makeFontPicker(selection: Binding<String>) -> some View {
        FontPickerView(selection: selection)
    }

    func makeActionButtonSelector(selectedButtonsBinding: Binding<[VideoPlayerActionButton]>) -> some View {
        ActionButtonSelectorView(selection: selectedButtonsBinding)
    }

    #if os(tvOS)

    func makeResumeOffset(selection: Binding<Int>) -> some View {
        ResumeOffsetPickerView(selection: selection)
    }

    func makeSubtitleSize(selection: Binding<Int>) -> some View {
        SubtitleSizePickerView(selection: selection)
    }

    #elseif os(iOS)

    @ViewBuilder
    func makeGestureSettings() -> some View {
        GestureSettingsView()
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        VideoPlayerSettingsView()
    }
}
