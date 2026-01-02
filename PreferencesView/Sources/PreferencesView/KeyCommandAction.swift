//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

public struct KeyCommandAction {

    let title: String
    let subtitle: String?
    let input: String
    let modifierFlags: UIKeyModifierFlags
    let action: () -> Void

    public init(
        title: String,
        subtitle: String? = nil,
        input: String,
        modifierFlags: UIKeyModifierFlags = [],
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.input = input
        self.modifierFlags = modifierFlags
        self.action = action
    }
}

extension KeyCommandAction: Equatable {

    public static func == (lhs: KeyCommandAction, rhs: KeyCommandAction) -> Bool {
        lhs.input == rhs.input
    }
}
