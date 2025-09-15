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

    @Default(.VideoPlayer.Gesture.horizontalPanAction)
    private var horizontalPanAction
    @Default(.VideoPlayer.Gesture.horizontalSwipeAction)
    private var horizontalSwipeAction
    @Default(.VideoPlayer.Gesture.longPressAction)
    private var longPressGesture
    @Default(.VideoPlayer.Gesture.multiTapGesture)
    private var multiTapGesture
    @Default(.VideoPlayer.Gesture.doubleTouchGesture)
    private var doubleTouchGesture
    @Default(.VideoPlayer.Gesture.pinchGesture)
    private var pinchGesture
    @Default(.VideoPlayer.Gesture.verticalPanLeftAction)
    private var verticalPanLeftAction
    @Default(.VideoPlayer.Gesture.verticalPanRightAction)
    private var verticalPanRightAction

    var body: some View {
        Form {

            Section {

                // TODO: make toggle sections

                CaseIterablePicker(L10n.horizontalPan, selection: $horizontalPanAction)
                    .disabled(horizontalSwipeAction != .none)

                CaseIterablePicker(L10n.horizontalSwipe, selection: $horizontalSwipeAction)
                    .disabled(horizontalPanAction != .none)

                CaseIterablePicker(L10n.longPress, selection: $longPressGesture)

                CaseIterablePicker(L10n.multiTap, selection: $multiTapGesture)

                CaseIterablePicker(L10n.doubleTouch, selection: $doubleTouchGesture)

                CaseIterablePicker(L10n.pinch, selection: $pinchGesture)

                CaseIterablePicker(L10n.leftVerticalPan, selection: $verticalPanLeftAction)

                CaseIterablePicker(L10n.rightVerticalPan, selection: $verticalPanRightAction)
            }
        }
        .navigationTitle(L10n.gestures)
    }
}
