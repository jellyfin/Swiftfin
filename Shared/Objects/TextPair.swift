//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: better context naming than for "display" purposes

struct TextPair: Displayable, Identifiable {

    let displayTitle: String
    let subtitle: String

    var id: String {
        displayTitle.appending(subtitle)
    }
}
