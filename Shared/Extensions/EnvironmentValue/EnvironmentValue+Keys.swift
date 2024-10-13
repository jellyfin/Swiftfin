//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension EnvironmentValues {

    struct AccentColor: EnvironmentKey {
        static let defaultValue: Binding<Color> = .constant(Color.jellyfinPurple)
    }

    struct AudioOffsetKey: EnvironmentKey {
        static let defaultValue: Binding<Int> = .constant(0)
    }

    struct AspectFilledKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(false)
    }

//    struct CurrentOverlayTypeKey: EnvironmentKey {
//        static let defaultValue: Binding<VideoPlayer.OverlayType> = .constant(.main)
//    }

    struct IsEditingKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }

    struct IsScrubbingKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(false)
    }

    struct IsSelectedKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }

    // TODO: change to use `PlaybackRate` and rename
    struct PlaybackSpeedKey: EnvironmentKey {
        static let defaultValue: Binding<Double> = .constant(1)
    }

    struct SafeAreaInsetsKey: EnvironmentKey {
        static var defaultValue: Binding<EdgeInsets> = .constant(.zero)
    }

    struct ScrubbingProgressKey: EnvironmentKey {
        static var defaultValue: Binding<ProgressBox> = .constant(.init())
    }

    struct SubtitleOffsetKey: EnvironmentKey {
        static let defaultValue: Binding<Int> = .constant(0)
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
