//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AudioOffset: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

struct AspectFilled: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

struct CurrentOverlayType: EnvironmentKey {
    static let defaultValue: Binding<ItemVideoPlayer.OverlayType?> = .constant(nil)
}

struct IsScrubbing: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

struct PresentingPlaybackSettings: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets.asEdgeInsets ?? .zero
    }
}

struct ScrubbedProgress: EnvironmentKey {
    static let defaultValue: Binding<CGFloat> = .constant(0)
}

struct SubtitleOffset: EnvironmentKey {
    static let defaultValue: Binding<Int> = .constant(0)
}

extension EnvironmentValues {
    
    var audioOffset: Binding<Int> {
        get { self[AudioOffset.self] }
        set { self[AudioOffset.self] = newValue }
    }

    var aspectFilled: Binding<Bool> {
        get { self[AspectFilled.self] }
        set { self[AspectFilled.self] = newValue }
    }

    var currentOverlayType: Binding<ItemVideoPlayer.OverlayType?> {
        get { self[CurrentOverlayType.self] }
        set { self[CurrentOverlayType.self] = newValue }
    }

    var isScrubbing: Binding<Bool> {
        get { self[IsScrubbing.self] }
        set { self[IsScrubbing.self] = newValue }
    }

    var presentingPlaybackSettings: Binding<Bool> {
        get { self[PresentingPlaybackSettings.self] }
        set { self[PresentingPlaybackSettings.self] = newValue }
    }

    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }

    var scrubbedProgress: Binding<CGFloat> {
        get { self[ScrubbedProgress.self] }
        set { self[ScrubbedProgress.self] = newValue }
    }
    
    var subtitleOffset: Binding<Int> {
        get { self[SubtitleOffset.self] }
        set { self[SubtitleOffset.self] = newValue }
    }
}
