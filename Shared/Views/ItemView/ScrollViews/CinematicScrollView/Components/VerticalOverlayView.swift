//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView.CinematicScrollView {

    struct VerticalOverlayView: View {

        @ObservedObject
        var viewModel: ItemViewModel

        let usePrimaryImage: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .center, spacing: 10) {
                    if !usePrimaryImage {
                        ImageView(viewModel.item.imageURL(.logo, maxHeight: 100))
                            .placeholder { _ in
                                EmptyView()
                            }
                            .failure {
                                Marquee(viewModel.item.displayTitle)
                                    .font(.largeTitle.weight(.semibold))
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                            }
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100, alignment: .bottom)
                    }

                    MetadataView(viewModel: viewModel)
                        .padding(.horizontal)

                    Group {
                        if viewModel.item.presentPlayButton {
                            ItemView.PlayButton(viewModel: viewModel)
                                .frame(height: 50)
                        }

                        ItemView.ActionButtonHStack(viewModel: viewModel)
                            .foregroundStyle(.white)
                            .frame(height: 50)
                    }
                    .frame(maxWidth: 300)
                }
                .frame(maxWidth: .infinity)

                ItemView.OverviewView(item: viewModel.item)
                    .overviewLineLimit(3)
                    .taglineLineLimit(2)
                    .foregroundColor(.white)

                ItemView.AttributesHStack(
                    attributes: StoredValues[.User.itemViewAttributes],
                    viewModel: viewModel,
                    alignment: .leading
                )
            }
        }
    }
}
