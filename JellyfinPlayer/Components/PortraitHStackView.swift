//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

public protocol PortraitImageStackable {
    func imageURLContsructor(maxWidth: Int) -> URL
    var title: String { get }
    var description: String? { get }
    var blurHash: String { get }
}

struct PortraitImageHStackView<NavigationView: View, ItemType: PortraitImageStackable>: View {
    
    let title: String
    let items: [ItemType]
    let maxWidth: Int
    let navigationView: (ItemType) -> NavigationView
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
                .padding(.top, 3)
                .padding(.leading, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack {
                    Spacer().frame(height: 8)
                    HStack {
                        Spacer().frame(width: 16)
                        ForEach(items, id: \.title) { item in
                            NavigationLink(
                                destination: LazyView {
                                    navigationView(item)
                                },
                                label: {
                                    VStack {
                                        ImageView(src: item.imageURLContsructor(maxWidth: maxWidth),
                                                  bh: item.blurHash)
                                            .frame(width: 100, height: CGFloat(maxWidth))
                                            .cornerRadius(10)
                                            .shadow(radius: 4, y: 2)
                                        
                                        Text(item.title)
                                            .font(.footnote)
                                            .fontWeight(.regular)
                                            .lineLimit(1)
                                            .frame(width: 100)
                                            .foregroundColor(.primary)
                                        
                                        if let description = item.description {
                                            Text(description)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                                .frame(width: 100)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                })
                        }
                        Spacer().frame(width: UIDevice.current.userInterfaceIdiom == .pad ? 16 : 55)
                    }
                }
            }.padding(.top, -3)
        }
    }
}
