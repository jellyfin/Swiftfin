//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CurrentOverlayType: EnvironmentKey {
    static let defaultValue: Binding<ItemVideoPlayer.OverlayType?> = .constant(nil)
}

struct IsScrubbing: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {

    var currentOverlayType: Binding<ItemVideoPlayer.OverlayType?> {
        get { self[CurrentOverlayType.self] }
        set { self[CurrentOverlayType.self] = newValue }
    }

    var isScrubbing: Binding<Bool> {
        get { self[IsScrubbing.self] }
        set { self[IsScrubbing.self] = newValue }
    }
}
