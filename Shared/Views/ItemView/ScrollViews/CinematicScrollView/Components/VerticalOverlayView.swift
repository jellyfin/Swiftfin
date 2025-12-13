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

        private let buttonHeight: CGFloat = 50

        // MARK: - Body

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .center, spacing: 10) {
                    if !usePrimaryImage {
                        logoView
                    }

                    MetadataView(viewModel: viewModel)
                        .padding(.horizontal)

                    if viewModel.item.presentPlayButton {
                        ItemView.PlayButton(viewModel: viewModel)
                            .frame(height: buttonHeight)
                    }

                    ItemView.ActionButtonHStack(viewModel: viewModel)
                        .foregroundStyle(.white)
                        .frame(height: buttonHeight)
                }
                .frame(maxWidth: .infinity)

                ItemView.OverviewView(item: viewModel.item)
                    .overviewLineLimit(3)
                    .taglineLineLimit(2)
                    .foregroundStyle(.white)

                ItemView.AttributesHStack(
                    attributes: StoredValues[.User.itemViewAttributes],
                    viewModel: viewModel,
                    alignment: .leading
                )
            }
        }

        // MARK: - Logo View

        @ViewBuilder
        private var logoView: some View {
            ImageView(viewModel.item.imageURL(.logo, maxHeight: 100))
                .placeholder { _ in
                    EmptyView()
                }
                .failure {
                    Marquee(viewModel.item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundStyle(.white)
                }
                .aspectRatio(contentMode: .fit)
                .frame(height: 100, alignment: .bottom)
        }
    }
}
