//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Look at name spacing

struct AudioOffset: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

struct AspectFilled: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

struct CurrentOverlayType: EnvironmentKey {
    static let defaultValue: Binding<VideoPlayer.OverlayType> = .constant(.main)
}

struct IsScrubbing: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

struct PlaybackSpeedKey: EnvironmentKey {
    static let defaultValue: Binding<Float> = .constant(1)
}

struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets.asEdgeInsets ?? .zero
    }
}

struct SubtitleOffset: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

struct IsPresentingOverlayKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {

    var isPresentingOverlay: Binding<Bool> {
        get { self[IsPresentingOverlayKey.self] }
        set { self[IsPresentingOverlayKey.self] = newValue }
    }

    var audioOffset: Binding<Int> {
        get { self[AudioOffset.self] }
        set { self[AudioOffset.self] = newValue }
    }

    var aspectFilled: Binding<Bool> {
        get { self[AspectFilled.self] }
        set { self[AspectFilled.self] = newValue }
    }

    var currentOverlayType: Binding<VideoPlayer.OverlayType> {
        get { self[CurrentOverlayType.self] }
        set { self[CurrentOverlayType.self] = newValue }
    }

    var isScrubbing: Binding<Bool> {
        get { self[IsScrubbing.self] }
        set { self[IsScrubbing.self] = newValue }
    }

    var playbackSpeed: Binding<Float> {
        get { self[PlaybackSpeedKey.self] }
        set { self[PlaybackSpeedKey.self] = newValue }
    }

    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }

    var subtitleOffset: Binding<Int> {
        get { self[SubtitleOffset.self] }
        set { self[SubtitleOffset.self] = newValue }
    }
}
