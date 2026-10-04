//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import UIKit

extension CGSize {

    var aspectRatio: CGFloat? {
        guard width > 0, height > 0,
              width.isFinite, height.isFinite
        else { return nil }
        let ratio = width / height
        return ratio > 0 && ratio.isFinite ? ratio : nil
    }

    var isLandscape: Bool {
        width >= height
    }

    var isPortrait: Bool {
        height >= width
    }
}
