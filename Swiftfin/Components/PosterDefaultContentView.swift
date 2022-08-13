//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterButtonDefaultContentView<Item: Poster>: View {

    let item: Item

    var body: some View {
        VStack(alignment: .leading) {
            if item.showTitle {
                Text(item.title)
                    .font(.footnote)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            if let description = item.subtitle {
                Text(description)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
}
