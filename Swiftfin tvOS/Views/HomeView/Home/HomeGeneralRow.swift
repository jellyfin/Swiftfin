//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension HomeView {
    struct HomeGeneralRow: View {
        public let viewModel: ItemTypeLibraryViewModel
        public let focusedImage: FocusState<String?>.Binding
        
        public let title: String
        public let subtitle: String?
        
        var body: some View {
            Group {
                HomeSectionText(title: title, subtitle: subtitle)
                HomeItemRow(items: viewModel.items, size: .four, focusPrefix: "general_\(viewModel)", focusedImage: focusedImage)
            }
        }
    }
}
