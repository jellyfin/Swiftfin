//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct TextPairView: View {

    let leading: String
    let trailing: String

    var body: some View {
        HStack {
            Text(leading)

            Spacer()

            Text(trailing)
                .foregroundColor(.secondary)
        }
    }
}

extension TextPairView {

    init(_ textPair: TextPair) {
        self.init(
            leading: textPair.displayTitle,
            trailing: textPair.subtitle
        )
    }
}
