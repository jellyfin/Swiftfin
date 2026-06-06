//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Material {

    func tinted(_ color: Color) -> TintedMaterialShapeStyle {
        .init(material: self, tint: color)
    }
}

struct TintedMaterialShapeStyle: ShapeStyle {

    let material: Material
    let tint: Color

    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        AnyShapeStyle(material)
    }
}

extension Shape {

    func fill(_ style: TintedMaterialShapeStyle) -> some View {
        fill(style.material)
            .background {
                fill(style.tint)
            }
    }
}
