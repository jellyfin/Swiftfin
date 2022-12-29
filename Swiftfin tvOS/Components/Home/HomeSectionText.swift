//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct HomeSectionText: View {
    @Environment(\.safeAreaInsets) private var edgeInsets: EdgeInsets
    
    public var title: String
    public var subtitle: String?
    
    public var visible = true
    public var increaseOffset = false
    
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
        }
        .padding(.leading, edgeInsets.leading)
        .padding(.bottom, subtitle == nil ? 0 : 20)
        
        .animation(.linear(duration: 0.25), value: increaseOffset)
        .offset(x: 0, y: increaseOffset ? 20 : 35)
    }
}
