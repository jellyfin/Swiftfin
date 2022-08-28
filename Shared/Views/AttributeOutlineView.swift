//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Replace with `attributeStyle`
struct AttributeOutlineView: View {

    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(Color(UIColor.lightGray))
            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color(UIColor.lightGray), lineWidth: 1)
            )
    }
}
