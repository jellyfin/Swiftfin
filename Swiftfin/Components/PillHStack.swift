//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PillHStack<Data: RandomAccessCollection>: View where Data.Element: Displayable, Data.Index == Int {

    let title: String
    let data: Data
    let action: (Data.Element) -> Void

    var body: some View {
        Section {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(data, id: \.displayTitle) { item in
                        Button {
                            action(item)
                        } label: {
                            Text(item.displayTitle)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(10)
                                .background {
                                    Color.systemFill
                                }
                                .cornerRadius(10)
                        }
                        .foregroundStyle(.primary, .secondary)
                    }
                }
                .edgePadding(.horizontal)
            }
            .scrollIndicators(.hidden)
        } header: {
            DefaultHeader(title: title)
        }
    }
}
