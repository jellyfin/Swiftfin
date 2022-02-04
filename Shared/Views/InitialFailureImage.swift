//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct InitialFailureImage: View {
    
    let initials: String
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color(UIColor.darkGray))

            Text(initials)
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
    }
}
