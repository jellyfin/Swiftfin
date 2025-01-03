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

    struct AccentColor: EnvironmentKey {
        static let defaultValue: Binding<Color> = .constant(Color.jellyfinPurple)
    }

    struct AudioOffsetKey: EnvironmentKey {
        static let defaultValue: Binding<Int> = .constant(0)
    }

    struct AspectFilledKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(false)
    }

    struct CurrentOverlayTypeKey: EnvironmentKey {
        static let defaultValue: Binding<VideoPlayer.OverlayType> = .constant(.main)
    }

    struct IsEditingKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }

    struct IsScrubbingKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(false)
    }

    struct IsSelectedKey: EnvironmentKey {
        static let defaultValue: Bool = false
    }

    struct PlaybackSpeedKey: EnvironmentKey {
        static let defaultValue: Binding<Double> = .constant(1)
    }

    // TODO: See if we can use a root `GeometryReader` that sets the environment value
    struct SafeAreaInsetsKey: EnvironmentKey {
        static var defaultValue: EdgeInsets {
            UIApplication.shared.keyWindow?.safeAreaInsets.asEdgeInsets ?? .zero
        }
    }

    struct SubtitleOffsetKey: EnvironmentKey {
        static let defaultValue: Binding<Int> = .constant(0)
    }

    struct IsPresentingOverlayKey: EnvironmentKey {
        static let defaultValue: Binding<Bool> = .constant(false)
    }
}
