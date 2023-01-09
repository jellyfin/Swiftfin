//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EdgeInsets {

    func mutating(_ keyPath: WritableKeyPath<EdgeInsets, CGFloat>, to newValue: CGFloat) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }
}

extension UIEdgeInsets {

    var asEdgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
