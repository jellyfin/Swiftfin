//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct ProgramBlock: Identifiable {

    let programs: [BaseItemDto]
    let start: Date
    let end: Date
    let leadingOffset: CGFloat
    let width: CGFloat

    var isGroup: Bool {
        programs.count > 1
    }

    var id: String {
        guard let firstID = programs.first?.id else {
            return "\(start.timeIntervalSince1970)"
        }

        return isGroup ? "group-\(firstID)-\(programs.count)" : firstID
    }

    func isAiring(at date: Date) -> Bool {
        programs.contains { program in
            guard let start = program.startDate, let end = program.endDate else { return false }
            return (start ... end).contains(date)
        }
    }
}
