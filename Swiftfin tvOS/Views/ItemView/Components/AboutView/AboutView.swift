//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct AboutView: View {

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {

                Text(L10n.about)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibility(addTraits: [.isHeader])
                    .padding(.leading, 50)

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 30) {
                        ImageCard(viewModel: viewModel)

                        OverviewCard(item: viewModel.item)

                        if let mediaSources = viewModel.item.mediaSources {
                            ForEach(mediaSources) { source in
                                MediaSourcesCard(subtitle: mediaSources.count > 1 ? source.displayTitle : nil, source: source)
                            }
                        }

                        if viewModel.item.hasRatings {
                            RatingsCard(item: viewModel.item)
                        }
                    }
                    .padding(50)
                }
            }
            .focusSection()
        }
    }
}
