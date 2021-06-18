/*
 * JellyfinPlayer/Swiftfin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import JellyfinAPI
import Combine

struct ContinueWatchingView: View {
    var items: [BaseItemDto]
    @Namespace private var namespace

    var body: some View {
        VStack(alignment: .leading) {
            if items.count > 0 {
                Text("Continue Watching")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.leading, 90)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        Spacer().frame(width: 45)
                        ForEach(items, id: \.id) { item in
                            NavigationLink(destination: Text("itemv")) {
                                LandscapeItemElement(item: item)
                            }.buttonStyle(PlainNavigationLinkButtonStyle())
                                .prefersDefaultFocus(item == items.first, in: namespace)
                        }
                        Spacer().frame(width: 45)
                    }
                }.frame(height: 330)
            } else {
                EmptyView()
            }
        }
    }
}
