//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension EnvironmentValues {

    struct AudioOffsetKey: EnvironmentKey {
        static let defaultValue: Binding<TimeInterval> = .constant(0)
    }

    struct AspectFilledKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(false)
    }

    struct IsEditingKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }

    struct IsInMenuKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }

    struct IsGestureLockedKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(false)
    }

    struct IsScrubbingKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(false)
    }

    struct IsSelectedKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }

    struct SafeAreaInsetsKey: EnvironmentKey {
        static var defaultValue: EdgeInsets = .zero
    }

    struct SubtitleOffsetKey: EnvironmentKey {
        static let defaultValue: Binding<TimeInterval> = .constant(0)
    }

    struct IsPresentingOverlayKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(false)
    }

    struct IsPresentingDrawerKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(false)
    }

    struct SelectedMediaPlayerSupplementKey: EnvironmentKey {
        static let defaultValue: Binding<AnyMediaPlayerSupplement?> = .constant(nil)
    }

    struct ScrubbedSecondsKey: EnvironmentKey {
        static let defaultValue: Binding<TimeInterval> = .constant(0)
    }
}
