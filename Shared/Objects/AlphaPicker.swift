//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import UIKit

class AlphaPicker {

    static let characters: [String] = UILocalizedIndexedCollation.current().sectionTitles.sorted()
    var selection: String?

    var nameStartsWith: String {
        if selection == "#" {
            return ""
        } else {
            return selection ?? ""
        }
    }

    var nameLessThan: String {
        if selection == "#" {
            return "A"
        } else {
            return ""
        }
    }

    init(_ letter: String?) {
        self.selection = letter
    }

    func updateSelection(_ letter: String?) {
        if selection == letter {
            selection = nil
        } else {
            selection = letter
        }
    }
}
