//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum LetterPickerOrientation: String, CaseIterable, Displayable, Storable {

    case disabled
    case leading
    case trailing

    var displayTitle: String {
        switch self {
        case .disabled:
            L10n.disabled
        case .leading:
            L10n.left
        case .trailing:
            L10n.right
        }
    }

    var alignment: Alignment? {
        switch self {
        case .disabled:
            nil
        case .leading:
            .leading
        case .trailing:
            .trailing
        }
    }

    var edge: HorizontalEdge? {
        switch self {
        case .disabled:
            nil
        case .leading:
            .leading
        case .trailing:
            .trailing
        }
    }
}
