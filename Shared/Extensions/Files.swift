//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

#if os(iOS)
extension FileManager {

    var availableStorage: Int {
        let availableStorage: Int64

        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)

        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])

            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                availableStorage = capacity
            } else {
                availableStorage = -1
            }
        } catch {
            availableStorage = -1
        }

        return Int(availableStorage)
    }
}
#endif
