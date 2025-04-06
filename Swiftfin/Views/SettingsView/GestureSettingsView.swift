//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: organize into a better structure
// TODO: add footer descriptions to each explaining the
//       the gesture + why horizontal pan/swipe caveat
// TODO: add page describing each action?

struct GestureSettingsView: View {

    @Default(.VideoPlayer.Gesture.horizontalPanGesture)
    private var horizontalPanGesture
    @Default(.VideoPlayer.Gesture.horizontalSwipeGesture)
    private var horizontalSwipeGesture
    @Default(.VideoPlayer.Gesture.longPressGesture)
    private var longPressGesture
    @Default(.VideoPlayer.Gesture.multiTapGesture)
    private var multiTapGesture
    @Default(.VideoPlayer.Gesture.doubleTouchGesture)
    private var doubleTouchGesture
    @Default(.VideoPlayer.Gesture.pinchGesture)
    private var pinchGesture
    @Default(.VideoPlayer.Gesture.verticalPanGestureLeft)
    private var verticalPanGestureLeft
    @Default(.VideoPlayer.Gesture.verticalPanGestureRight)
    private var verticalPanGestureRight

    var body: some View {
        Form {

            Section {

                CaseIterablePicker(L10n.horizontalPan, selection: $horizontalPanGesture)
                    .disabled(horizontalSwipeGesture != .none && horizontalPanGesture == .none)

                CaseIterablePicker(L10n.horizontalSwipe, selection: $horizontalSwipeGesture)
                    .disabled(horizontalPanGesture != .none && horizontalSwipeGesture == .none)

                CaseIterablePicker(L10n.longPress, selection: $longPressGesture)

                CaseIterablePicker(L10n.multiTap, selection: $multiTapGesture)

                CaseIterablePicker(L10n.doubleTouch, selection: $doubleTouchGesture)

                CaseIterablePicker(L10n.pinch, selection: $pinchGesture)

                CaseIterablePicker(L10n.leftVerticalPan, selection: $verticalPanGestureLeft)

                CaseIterablePicker(L10n.rightVerticalPan, selection: $verticalPanGestureRight)
            }
        }
        .navigationTitle(L10n.gestures)
    }
}
