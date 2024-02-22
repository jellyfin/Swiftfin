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

    /* TODO: Enable with the AlphaPickerBar for determining which side of the screen in the settings
     enum Setting {

         case none
         case leading
         case trailing

         var displayTitle: String {
             switch self {
             case .none:
                 return L10n.none
             case .leading:
                 return "Left" // L10n.left
             case .trailing:
                 return "Right" // L10n.right
             }
         }
     }*/

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
        self.selection = letter ?? nil
    }

    func updateSelection(_ letter: String?) {
        if selection == letter {
            selection = nil
        } else {
            selection = letter
        }
    }
}
