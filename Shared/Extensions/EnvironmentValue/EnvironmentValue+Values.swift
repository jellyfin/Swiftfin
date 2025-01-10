//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EnvironmentValues {

    var selectedMediaPlayerSupplement: Binding<AnyMediaPlayerSupplement?> {
        get { self[SelectedMediaPlayerSupplementKey.self] }
        set { self[SelectedMediaPlayerSupplementKey.self] = newValue }
    }

    var scrubbedSeconds: Binding<TimeInterval> {
        get { self[ScrubbedSecondsKey.self] }
        set { self[ScrubbedSecondsKey.self] = newValue }
    }

    var audioOffset: Binding<TimeInterval> {
        get { self[AudioOffsetKey.self] }
        set { self[AudioOffsetKey.self] = newValue }
    }

    var isAspectFilled: Binding<Bool> {
        get { self[AspectFilledKey.self] }
        set { self[AspectFilledKey.self] = newValue }
    }

    var isEditing: Bool {
        get { self[IsEditingKey.self] }
        set { self[IsEditingKey.self] = newValue }
    }

    var isInMenu: Bool {
        get { self[IsInMenuKey.self] }
        set { self[IsInMenuKey.self] = newValue }
    }

    var isGestureLocked: Binding<Bool> {
        get { self[IsGestureLockedKey.self] }
        set { self[IsGestureLockedKey.self] = newValue }
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

    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }

    var subtitleOffset: Binding<TimeInterval> {
        get { self[SubtitleOffsetKey.self] }
        set { self[SubtitleOffsetKey.self] = newValue }
    }
}
