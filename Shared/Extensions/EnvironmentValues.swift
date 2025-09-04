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

//    @Entry
//    var isAspectFilled: Binding<Bool> = .constant(false)

    @Entry
    var isEditing: Bool = false

    // TODO: move to container state
    @Entry
    var isGestureLocked: Binding<Bool> = .constant(false)

    @Entry
    var isInMenu: Bool = false

    @Entry
    var isSelected: Bool = false

    @Entry
    var panGestureAction: PanGestureAction? = nil

    @Entry
    var pinchGestureAction: PinchGestureAction? = nil

    @Entry
    var playbackSpeed: Binding<Double> = .constant(1)

    @Entry
    var safeAreaInsets: EdgeInsets = UIApplication.shared.keyWindow?.safeAreaInsets.asEdgeInsets ?? .zero

    @Entry
    var subtitleOffset: Binding<Duration> = .constant(.zero)

    @Entry
    var tapGestureAction: TapGestureAction? = nil
}

struct PanGestureAction {

    let action: (
        _ point: CGPoint,
        _ velocity: CGFloat,
        _ location: CGPoint,
        _ state: UIGestureRecognizer.State
    ) -> Void

    func callAsFunction(
        point: CGPoint,
        velocity: CGFloat,
        location: CGPoint,
        state: UIGestureRecognizer.State
    ) {
        action(point, velocity, location, state)
    }
}

struct PinchGestureAction {

    let action: (
        _ scale: CGFloat,
        _ velocity: CGFloat,
        _ state: UIGestureRecognizer.State
    ) -> Void

    func callAsFunction(
        scale: CGFloat,
        velocity: CGFloat,
        state: UIGestureRecognizer.State
    ) {
        action(scale, velocity, state)
    }
}

struct SwipeGestureAction {

    let action: (Direction) -> Void

    func callAsFunction(_ direction: Direction) {
        action(direction)
    }
}

struct TapGestureAction {

    let action: (_ point: UnitPoint, _ count: Int) -> Void

    func callAsFunction(point: UnitPoint, count: Int) {
        action(point, count)
    }
}
