//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

struct LibraryPageProgress {
    let offset: Int
    let pageSize: Int
    let consumedRows: Int
    let totalRows: Int?

    var nextOffset: Int {
        offset + consumedRows
    }

    var hasNextPage: Bool {
        guard consumedRows > 0 else { return false }
        if let totalRows, totalRows >= nextOffset {
            return nextOffset < totalRows
        }
        return consumedRows >= pageSize
    }
}
