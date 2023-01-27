//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct AboutView: View {

        @EnvironmentObject
        private var itemRouter: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(alignment: .leading) {
                L10n.about.text
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibility(addTraits: [.isHeader])
                    .padding(.horizontal)
                    .if(UIDevice.isIPad) { view in
                        view.padding(.horizontal)
                    }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ImageView(
                            viewModel.item.type == .episode ? viewModel.item.seriesImageSource(.primary, maxWidth: 300) : viewModel
                                .item.imageSource(.primary, maxWidth: 300)
                        )
                        .posterStyle(type: .portrait, width: 130)
                        .accessibilityIgnoresInvertColors()

                        Button {
                            itemRouter.route(to: \.itemOverview, viewModel.item)
                        } label: {
                            ZStack {

                                Color.secondarySystemFill
                                    .cornerRadius(10)

                                VStack(alignment: .leading, spacing: 10) {
                                    Text(viewModel.item.displayName)
                                        .font(.title2)
                                        .fontWeight(.semibold)

                                    Spacer()

                                    if let overview = viewModel.item.overview {
                                        Text(overview)
                                            .lineLimit(4)
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    } else {
                                        L10n.noOverviewAvailable.text
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                            }
                            .frame(width: 330, height: 195)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .if(UIDevice.isIPad) { view in
                        view.padding(.horizontal)
                    }
                }
            }
        }
    }
}
