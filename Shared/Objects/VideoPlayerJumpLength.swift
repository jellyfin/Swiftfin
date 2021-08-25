//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import UIKit
import Defaults

enum VideoPlayerJumpLength: Int32, CaseIterable, Defaults.Serializable {
    case thirty = 30
    case fifteen = 15
    case ten = 10

    // TODO - Uncomment once iOS 15 released
//    case five = 5

    var label: String {
        return "\(self.rawValue) seconds"
    }

    func generateForwardImage(with font: UIFont) -> UIImage {
        let config = UIImage.SymbolConfiguration(font: font)
        let systemName: String

        switch self {
        case .thirty:
            systemName = "goforward.30"
        case .fifteen:
            systemName = "goforward.15"
        case .ten:
            systemName = "goforward.10"
//        case .five:
//            systemName = "goforward.5"
        }

        return UIImage(systemName: systemName, withConfiguration: config)!
    }

    func generateBackwardImage(with font: UIFont) -> UIImage {
        let config = UIImage.SymbolConfiguration(font: font)
        let systemName: String

        switch self {
        case .thirty:
            systemName = "gobackward.30"
        case .fifteen:
            systemName = "gobackward.15"
        case .ten:
            systemName = "gobackward.10"
//        case .five:
//            systemName = "gobackward.5"
        }

        return UIImage(systemName: systemName, withConfiguration: config)!
    }
}
