//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EnvironmentValues {

    @Entry
    var audioOffset: Binding<Int> = .constant(0)

    @Entry
    var aspectFilled: Binding<Bool> = .constant(false)

    @Entry
    var currentOverlayType: Binding<VideoPlayer.OverlayType> = .constant(.main)

    @Entry
    var isEditing: Bool = false

    @Entry
    var isPresentingOverlay: Binding<Bool> = .constant(false)

    @Entry
    var isScrubbing: Binding<Bool> = .constant(false)

    @Entry
    var isSelected: Bool = false

    @Entry
    var playbackSpeed: Binding<Double> = .constant(1)

    @Entry
    var safeAreaInsets: EdgeInsets = UIApplication.shared.keyWindow?.safeAreaInsets.asEdgeInsets ?? .zero

    @Entry
    var subtitleOffset: Binding<Int> = .constant(0)
}
