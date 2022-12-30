//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension HomeView {
    struct HomeSectionText: View {
        @Environment(\.safeAreaInsets) private var edgeInsets: EdgeInsets
        
        public var title: String
        public var subtitle: String?
        
        public var visible = true
        // I think it is impossible to detect if the focused item is directly below the text so this will probably remain unused
        // Maybe there is a way to detect clipping?
        public var increaseOffset = false
        
        public var callback: (() -> Void)?
        
        var body: some View {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .bold()
                        .foregroundColor(Color.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor.lightGray))
                    }
                }
                Spacer()
                if let callback = callback {
                    Button {
                        callback()
                    } label: {
                        Label(L10n.seeAll, systemImage: "chevron.right")
                            .font(.caption)
                    }
                }
            }
            .padding(.leading, edgeInsets.leading)
            .padding(.trailing, edgeInsets.trailing)
            .padding(.bottom, 20)
            
            .animation(.easeInOut(duration: 0.25), value: increaseOffset)
            .offset(x: 0, y: increaseOffset ? 20 : 35)
        }
    }
}
