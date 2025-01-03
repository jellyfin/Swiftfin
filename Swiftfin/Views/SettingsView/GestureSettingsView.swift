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

                CaseIterablePicker("Horizontal Pan", selection: $horizontalPanGesture)
                    .disabled(horizontalSwipeGesture != .none && horizontalPanGesture == .none)

                CaseIterablePicker("Horizontal Swipe", selection: $horizontalSwipeGesture)
                    .disabled(horizontalPanGesture != .none && horizontalSwipeGesture == .none)

                CaseIterablePicker("Long Press", selection: $longPressGesture)

                CaseIterablePicker("Multi Tap", selection: $multiTapGesture)

                CaseIterablePicker("Double Touch", selection: $doubleTouchGesture)

                CaseIterablePicker("Pinch", selection: $pinchGesture)

                CaseIterablePicker("Left Vertical Pan", selection: $verticalPanGestureLeft)

                CaseIterablePicker("Right Vertical Pan", selection: $verticalPanGestureRight)
            }
        }
        .navigationTitle(L10n.gestures)
    }
}
