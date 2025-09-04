//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension UIVideoPlayerContainerViewController {

    func handleTapGesture(
        location: UnitPoint,
        count: Int
    ) {
        if count == 1 {
            if containerState.isPresentingSupplement {
                if containerState.isCompact {
                    containerState.isPresentingPlaybackControls.toggle()
                } else {
                    containerState.selectedSupplement = nil
                }
            } else {
                containerState.isPresentingOverlay.toggle()
            }
        }
    }
}
