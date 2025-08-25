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
    var audioOffset: Binding<Duration> = .constant(.zero)

    @Entry
    var isAspectFilled: Binding<Bool> = .constant(false)

    @Entry
    var isEditing: Bool = false

    @Entry
    var isGestureLocked: Binding<Bool> = .constant(false)

    @Entry
    var isInMenu: Bool = false

    @Entry
    var isPresentingOverlay: Binding<Bool> = .constant(false)

    @Entry
    var isScrubbing: Binding<Bool> = .constant(false)

    @Entry
    var isSelected: Bool = false

    @Entry
    var panGestureAction: PanGestureAction = .init(action: { _, _, _, _ in })

    @Entry
    var playbackSpeed: Binding<Double> = .constant(1)

    @Entry
    var safeAreaInsets: EdgeInsets = UIApplication.shared.keyWindow?.safeAreaInsets.asEdgeInsets ?? .zero

    @Entry
    var selectedMediaPlayerSupplement: Binding<AnyMediaPlayerSupplement?> = .constant(nil)

    @Entry
    var subtitleOffset: Binding<Duration> = .constant(.zero)

    @Entry
    var tapGestureAction: TapGestureAction = .init(action: { _, _ in })
}

struct PanGestureAction {

    let action: (_ point: CGPoint, _ velocity: CGFloat, _ location: CGPoint, _ state: UIGestureRecognizer.State) -> Void

    func callAsFunction(_ point: CGPoint, _ velocity: CGFloat, _ location: CGPoint, _ state: UIGestureRecognizer.State) {
        action(point, velocity, location, state)
    }
}

struct TapGestureAction {

    let action: (_ point: UnitPoint, _ count: Int) -> Void

    func callAsFunction(_ point: UnitPoint, _ count: Int) {
        action(point, count)
    }
}
