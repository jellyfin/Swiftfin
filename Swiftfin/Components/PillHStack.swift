//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PillHStack<Item: PillStackable>: View {

    let title: String
    let items: [Item]
    let selectedAction: (Item) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .accessibility(addTraits: [.isHeader])
                .padding(.leading)
                .if(UIDevice.isIPad) { view in
                    view.padding(.leading)
                }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(items, id: \.title) { item in
                        Button {
                            selectedAction(item)
                        } label: {
                            ZStack {
                                Color(UIColor.systemFill)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .cornerRadius(10)

                                Text(item.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .fixedSize()
                                    .padding(10)
                            }
                            .fixedSize()
                        }
                    }
                }
                .padding(.horizontal)
                .if(UIDevice.isIPad) { view in
                    view.padding(.horizontal)
                }
            }
        }
    }
}
