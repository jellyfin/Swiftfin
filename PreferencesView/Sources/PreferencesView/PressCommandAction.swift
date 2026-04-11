//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

public struct PressCommandAction {

    let title: String
    let press: UIPress.PressType
    let action: () -> Void

    public init(
        title: String,
        press: UIPress.PressType,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.press = press
        self.action = action
    }
}

extension PressCommandAction: Equatable {

    public static func == (lhs: PressCommandAction, rhs: PressCommandAction) -> Bool {
        lhs.press == rhs.press
    }
}
