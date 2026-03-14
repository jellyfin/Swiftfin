//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: rename as not only used in section footers

extension LabelStyle where Self == SectionFooterWithImageLabelStyle<AnyShapeStyle> {

    static func sectionFooterWithImage<ImageStyle: ShapeStyle>(
        imageStyle: ImageStyle
    ) -> SectionFooterWithImageLabelStyle<ImageStyle> {
        SectionFooterWithImageLabelStyle(imageStyle: imageStyle)
    }
}

struct SectionFooterWithImageLabelStyle<ImageStyle: ShapeStyle>: LabelStyle {

    let imageStyle: ImageStyle

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            configuration.icon
                .foregroundStyle(imageStyle)
                .fontWeight(.bold)

            configuration.title
        }
    }
}
