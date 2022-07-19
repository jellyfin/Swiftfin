//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ListDetailsView: View {

    let title: String
    let items: [BaseItemDto.ItemDetail]

    var body: some View {
        VStack(alignment: .leading) {

            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .accessibility(addTraits: [.isHeader])

                ForEach(items, id: \.self.title) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.subheadline)
                        Text(item.content)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .font(.subheadline)
                            .foregroundColor(Color.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.bottom, 20)
        }
    }
}
