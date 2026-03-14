//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Text {

    @available(*, deprecated, message: "Just use `.displayTitle` manually instead")
    init(_ content: some Displayable) {
        self.init(verbatim: "\(content.displayTitle)")
    }
}
