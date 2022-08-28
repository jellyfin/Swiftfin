//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Replace with `attributeStyle`
struct AttributeFillView: View {

    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
            .hidden()
            .background {
                Color(UIColor.lightGray)
                    .cornerRadius(2)
                    .inverseMask(
                        Text(text)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                    )
            }
    }
}
