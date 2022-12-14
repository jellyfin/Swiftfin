//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

final class VideoPlayerSettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \VideoPlayerSettingsCoordinator.start)

    @Root
    var start = makeStart

    #if !os(tvOS)
    @Route(.push)
    var fontPicker = makeFontPicker
    @Route(.push)
    var gestureSettings = makeGestureSettings

    @ViewBuilder
    func makeFontPicker() -> some View {
        FontPickerView()
            .navigationTitle(L10n.subtitleFont)
    }

    @ViewBuilder
    func makeGestureSettings() -> some View {
        GestureSettingsView()
            .navigationTitle("Gestures")
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        VideoPlayerSettingsView()
    }
}

// struct VideoPlayerSettingsView: View {
//
//    var body: some View {
//        Text("")
//    }
// }
