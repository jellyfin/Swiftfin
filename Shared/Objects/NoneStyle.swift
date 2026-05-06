//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum NoneStyle: Displayable {

    case text
    case dash(Int)
    case custom(String)

    // swiftlint:disable:next hard_coded_display_string
    var displayTitle: String {
        switch self {
        case .text:
            return L10n.none
        case let .dash(length):
            assert(length >= 1, "Dash must have length of at least 1.")

            return String(repeating: .hyphen, count: length)
        case let .custom(text):
            assert(text.isNotEmpty, "Custom text must have length of at least 1.")

            return text
        }
    }
}
