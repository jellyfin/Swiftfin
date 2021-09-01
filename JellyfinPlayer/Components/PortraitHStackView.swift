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
    var failureInitials: String { get }
}

struct PortraitImageHStackView<TopBarView: View, NavigationView: View, ItemType: PortraitImageStackable>: View {
    
    let items: [ItemType]
    let maxWidth: Int
    let horizontalAlignment: HorizontalAlignment
    let topBarView: () -> TopBarView
    let navigationView: (ItemType) -> NavigationView
    
    init(items: [ItemType], maxWidth: Int, horizontalAlignment: HorizontalAlignment = .leading, topBarView: @escaping () -> TopBarView, navigationView: @escaping (ItemType) -> NavigationView) {
        self.items = items
        self.maxWidth = maxWidth
        self.horizontalAlignment = horizontalAlignment
        self.topBarView = topBarView
        self.navigationView = navigationView
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            topBarView()
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack {
                    Spacer().frame(height: 8)
                    HStack(alignment: .top) {
                        
                        Spacer().frame(width: 16)
                        
                        ForEach(items, id: \.title) { item in
                            NavigationLink(
                                destination: LazyView {
                                    navigationView(item)
                                },
                                label: {
                                    VStack {
                                        ImageView(src: item.imageURLContsructor(maxWidth: maxWidth),
                                                  bh: item.blurHash,
                                                  failureInitials: item.failureInitials)
                                            .frame(width: 100, height: CGFloat(maxWidth))
                                            .cornerRadius(10)
                                            .shadow(radius: 4, y: 2)
                                        
                                        Text(item.title)
                                            .font(.footnote)
                                            .fontWeight(.regular)
                                            .frame(width: 100)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                        
                                        if let description = item.description {
                                            Text(description)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .frame(width: 100)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
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
