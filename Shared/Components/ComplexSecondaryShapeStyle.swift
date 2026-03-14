//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ShapeStyle where Self == ComplexSecondaryShapeStyle {

    static var complexSecondary: ComplexSecondaryShapeStyle {
        .init()
    }
}

struct ComplexSecondaryShapeStyle: ShapeStyle {

    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        if environment.isOverComplexContent {
            // TODO: different on tvOS
            AnyShapeStyle(Material.ultraThinMaterial)
        } else {
            // TODO: change to a solid color
            AnyShapeStyle(Color.secondarySystemFill)
        }
    }
}
