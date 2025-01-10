//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CinematicItemAboutView: View {

    @ObservedObject
    var viewModel: ItemViewModel
    @FocusState
    private var focused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ImageView(viewModel.item.portraitHeaderViewURL(maxWidth: 257))
                .portraitPoster(width: 257)

            ZStack(alignment: .topLeading) {
                Color(UIColor.darkGray).opacity(focused ? 0.2 : 0)
                    .cornerRadius(9.5)
                    .frame(height: 385.5)

                VStack(alignment: .leading) {
                    L10n.about.text
                        .font(.title3)

                    Text(viewModel.item.overview ?? L10n.noOverviewAvailable)
                        .padding(.top, 2)
                        .lineLimit(7)
                }
                .padding()
            }
        }
        .focusable()
        .focused($focused)
        .padding(.horizontal, 50)
    }
}
