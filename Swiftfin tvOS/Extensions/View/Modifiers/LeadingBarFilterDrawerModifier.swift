//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LeadingBarFilterDrawerModifier<Filters: View>: ViewModifier {
    let filters: () -> Filters
    
    // Define collapsed and expanded widths
    private let collapsedWidth: CGFloat = 75
    private let expandedWidth: CGFloat = 200
    
    // Use @State to track focus state and determine current width
    @State private var isExpanded: Bool = false
    
    private var filterDrawerWidth: CGFloat {
        isExpanded ? expandedWidth : collapsedWidth
    }
    
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            content
                .padding(.leading, filterDrawerWidth + 10)
            
            filters()
                .padding(.leading, 10)
        }
    }
}
