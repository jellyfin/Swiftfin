//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ShapeStyle where Self == ComplexSecondaryShapeStyle {

    static var complexSecondary: ComplexSecondaryShapeStyle {
        .init()
    }
}

struct ComplexSecondaryShapeStyle: ShapeStyle {

    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        if environment.viewContext.contains(.isOverComplexContent) {
            // TODO: different on tvOS
            AnyShapeStyle(Material.ultraThinMaterial)
        } else {
            // TODO: change to a solid color
//            AnyShapeStyle(Color.secondarySystemFill)
            environment.colorScheme == .dark ?
                AnyShapeStyle(Color(.sRGB, red: 0.18, green: 0.18, blue: 0.18, opacity: 1.0)) :
                AnyShapeStyle(Color(.sRGB, red: 0.90, green: 0.90, blue: 0.90, opacity: 1.0))
        }
    }
}
