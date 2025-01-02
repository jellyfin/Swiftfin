//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EnvironmentValues {

    var accentColor: Binding<Color> {
        get { self[AccentColor.self] }
        set { self[AccentColor.self] = newValue }
    }

    var audioOffset: Binding<Int> {
        get { self[AudioOffsetKey.self] }
        set { self[AudioOffsetKey.self] = newValue }
    }

    var aspectFilled: Binding<Bool> {
        get { self[AspectFilledKey.self] }
        set { self[AspectFilledKey.self] = newValue }
    }

    var currentOverlayType: Binding<VideoPlayer.OverlayType> {
        get { self[CurrentOverlayTypeKey.self] }
        set { self[CurrentOverlayTypeKey.self] = newValue }
    }

    var isEditing: Bool {
        get { self[IsEditingKey.self] }
        set { self[IsEditingKey.self] = newValue }
    }

    var isPresentingOverlay: Binding<Bool> {
        get { self[IsPresentingOverlayKey.self] }
        set { self[IsPresentingOverlayKey.self] = newValue }
    }

    var isScrubbing: Binding<Bool> {
        get { self[IsScrubbingKey.self] }
        set { self[IsScrubbingKey.self] = newValue }
    }

    var isSelected: Bool {
        get { self[IsSelectedKey.self] }
        set { self[IsSelectedKey.self] = newValue }
    }

    var playbackSpeed: Binding<Double> {
        get { self[PlaybackSpeedKey.self] }
        set { self[PlaybackSpeedKey.self] = newValue }
    }

    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }

    var subtitleOffset: Binding<Int> {
        get { self[SubtitleOffsetKey.self] }
        set { self[SubtitleOffsetKey.self] = newValue }
    }
}
