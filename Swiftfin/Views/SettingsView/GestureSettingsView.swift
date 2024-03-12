//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

                CaseIterablePicker(title: "Horizontal Pan", selection: $horizontalPanGesture)
                    .disabled(horizontalSwipeGesture != .none && horizontalPanGesture == .none)

                CaseIterablePicker(title: "Horizontal Swipe", selection: $horizontalSwipeGesture)
                    .disabled(horizontalPanGesture != .none && horizontalSwipeGesture == .none)

                CaseIterablePicker(title: "Long Press", selection: $longPressGesture)

                CaseIterablePicker(title: "Multi Tap", selection: $multiTapGesture)

                CaseIterablePicker(title: "Double Touch", selection: $doubleTouchGesture)

                CaseIterablePicker(title: "Pinch", selection: $pinchGesture)

                CaseIterablePicker(title: "Left Vertical Pan", selection: $verticalPanGestureLeft)

                CaseIterablePicker(title: "Right Vertical Pan", selection: $verticalPanGestureRight)
            }
        }
        .navigationTitle("Gestures")
    }
}
