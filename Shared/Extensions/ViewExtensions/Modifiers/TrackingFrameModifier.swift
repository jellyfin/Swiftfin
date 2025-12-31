//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ScrollViewHeaderFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

struct EmptyCGRectPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect { .zero }
    static func reduce(value: inout Value, nextValue: () -> CGRect) {
        value = .zero
    }
}

struct TrackingFrameModifier<Key: PreferenceKey>: ViewModifier where Key.Value == CGRect {

    @Environment(\.frameForParentView)
    private var frameForParentView

    @State
    private var frame: CGRect = .zero
    @State
    private var safeAreaInsets: EdgeInsets = .zero

    private let containerCoordinateSpace: CoordinateSpace
    private let coordinateSpace: CoordinateSpace
    private let key: Key.Type?

    init(
        containerCoordinateSpace: CoordinateSpace = .global,
        coordinateSpace: CoordinateSpace,
        key: Key.Type? = nil
    ) {
        self.containerCoordinateSpace = containerCoordinateSpace
        self.coordinateSpace = coordinateSpace
        self.key = key
    }

    @ViewBuilder
    private func attachingFramePreference(
        @ViewBuilder to content: @escaping () -> some View
    ) -> some View {
        if let key {
            content().preference(key: key, value: frame)
        } else {
            content()
        }
    }

    func body(content: Content) -> some View {
        attachingFramePreference {
            content
                .trackingFrame(
                    in: containerCoordinateSpace,
                    $frame,
                    $safeAreaInsets
                )
                .environment(
                    \.frameForParentView,
                    frameForParentView.inserting(
                        value: .init(frame: frame, safeAreaInsets: safeAreaInsets),
                        for: coordinateSpace
                    )
                )
        }
    }
}
