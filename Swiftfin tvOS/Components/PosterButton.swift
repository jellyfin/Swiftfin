//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PortraitButton<ItemType: PortraitImageStackable>: View {
    
    @FocusState
    var isFocused: Bool
    
    let item: ItemType
    let selectedAction: (ItemType) -> Void

    var body: some View {
        VStack {
            Button {
                selectedAction(item)
            } label: {
                ImageView(item.imageURLConstructor(maxWidth: 300),
                          blurHash: item.blurHash)
                    .frame(width: 300, height: 450)
            }

            VStack(alignment: .leading) {
                if item.showTitle {
                    HStack {
                        Text(item.title)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                    .frame(width: 270)
                }
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                }
            }
            .padding(.top, isFocused ? 10 : 0)
            .scaleEffect(isFocused ? 1.2 : 1)
            .padding(.horizontal)
        }
        .focused($isFocused)
        .buttonStyle(CardButtonStyle())
        .animation(.easeOut(duration: isFocused ? 0.12 : 0.35), value: isFocused)
    }
}
