//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EdgeInsets {

    // TODO: finalize tvOS
    /// The padding for Views against contextual edges,
    /// typically the edges of the View's scene
    static let edgePadding: CGFloat = {
        #if os(tvOS)
        44
        #else
        if UIDevice.isPad {
            24
        } else {
            16
        }
        #endif
    }()

    static let edgeInsets: EdgeInsets = .init(edgePadding)

    init(_ constant: CGFloat) {
        self.init(top: constant, leading: constant, bottom: constant, trailing: constant)
    }

    init(vertical: CGFloat = 0, horizontal: CGFloat = 0) {
        self.init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }

    static let zero: EdgeInsets = .init()

    var vertical: CGFloat {
        top + bottom
    }
}

extension NSDirectionalEdgeInsets {

    init(constant: CGFloat) {
        self.init(top: constant, leading: constant, bottom: constant, trailing: constant)
    }

    init(vertical: CGFloat = 0, horizontal: CGFloat = 0) {
        self.init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }
}

extension UIEdgeInsets {

    var asEdgeInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
