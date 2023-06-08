//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView.AboutView {
    
    struct OverviewCard: View {
        
        let item: BaseItemDto
        
        var body: some View {
            Card(title: item.displayTitle)
//                .cardContent {
//                    TruncatedTextView(text: item.overview ?? L10n.noOverviewAvailable)
//                        .font(.subheadline)
//                        .lineLimit(4)
//                }
//                .alertContent {
//                    Text(item.overview ?? L10n.noOverviewAvailable)
//                }
        }
    }
}
