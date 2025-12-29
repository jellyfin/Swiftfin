//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FrameAndSafeAreaInsets {
    let frame: CGRect
    let safeAreaInsets: EdgeInsets

    static let zero: Self = .init(frame: .zero, safeAreaInsets: .zero)
}

extension EnvironmentValues {

    @Entry
    var audioOffset: Binding<Duration> = .constant(.zero)

    @Entry
    var frameForParentView: [CoordinateSpace: FrameAndSafeAreaInsets] = [:]

    @Entry
    var isEditing: Bool = false

    @Entry
    var isSelected: Bool = false

    @Entry
    var playbackSpeed: Binding<Double> = .constant(1)

    @available(*, deprecated, message: "Use `frameForParentView` instead")
    @Entry
    var safeAreaInsets: EdgeInsets = UIApplication.shared.keyWindow?.safeAreaInsets.asEdgeInsets ?? .zero

    @Entry
    var subtitleOffset: Binding<Duration> = .constant(.zero)
}
