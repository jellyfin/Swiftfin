//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct AboutView: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(alignment: .leading) {
                L10n.about.text
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibility(addTraits: [.isHeader])
                    .padding(.horizontal)
                    .if(UIDevice.isPad) { view in
                        view.padding(.horizontal)
                    }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ImageView(
                            viewModel.item.type == .episode ? viewModel.item.seriesImageSource(.primary, maxWidth: 300) : viewModel
                                .item.imageSource(.primary, maxWidth: 300)
                        )
                        .posterStyle(.portrait)
                        .frame(width: 130)
                        .accessibilityIgnoresInvertColors()

                        OverviewCard(item: viewModel.item)

                        if let mediaSources = viewModel.item.mediaSources {
                            ForEach(mediaSources) { source in
                                MediaSourcesCard(subtitle: mediaSources.count > 1 ? source.displayTitle : nil, source: source)
                            }
                        }

                        RatingsCard(item: viewModel.item)
                    }
                    .padding(.horizontal)
                    .if(UIDevice.isPad) { view in
                        view.padding(.horizontal)
                    }
                }
            }
        }
    }
}
