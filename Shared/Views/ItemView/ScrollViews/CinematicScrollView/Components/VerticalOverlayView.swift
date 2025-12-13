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

        private let buttonHeight: CGFloat = 50
        private let maxButtonWidth: CGFloat = 300

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @ObservedObject
        var viewModel: ItemViewModel

        let usePrimaryImage: Bool

        // MARK: - Body

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
                                    .font(.largeTitle)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .foregroundStyle(.white)
                            }
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 100, alignment: .bottom)
                    }

                    MetadataView(viewModel: viewModel)
                        .padding(.horizontal)

                    Group {
                        if viewModel.item.presentPlayButton {
                            ItemView.PlayButton(viewModel: viewModel)
                                .frame(height: buttonHeight)
                        }

                        ItemView.ActionButtonHStack(viewModel: viewModel)
                            .foregroundStyle(.white)
                            .frame(height: buttonHeight)
                    }
                    .frame(maxWidth: maxButtonWidth)
                }
                .frame(maxWidth: .infinity)

                ItemView.OverviewView(item: viewModel.item)
                    .overviewLineLimit(3)
                    .taglineLineLimit(2)
                    .foregroundStyle(.white)

                ItemView.AttributesHStack(
                    attributes: attributes,
                    viewModel: viewModel,
                    alignment: .leading
                )
            }
        }
    }
}
