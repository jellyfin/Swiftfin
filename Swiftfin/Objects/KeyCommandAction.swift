//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import UIKit

struct KeyCommandAction {

    let title: String
    let input: String
    let modifierFlags: UIKeyModifierFlags
    let action: () -> Void

    init(
        title: String,
        input: String,
        modifierFlags: UIKeyModifierFlags = [],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.input = input
        self.modifierFlags = modifierFlags
        self.action = action
    }
}

extension KeyCommandAction: Equatable {

    static func == (lhs: KeyCommandAction, rhs: KeyCommandAction) -> Bool {
        lhs.input == rhs.input
    }
}
