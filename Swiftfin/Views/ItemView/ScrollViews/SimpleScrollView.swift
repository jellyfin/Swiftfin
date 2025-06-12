//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct SimpleScrollView<Content: View>: ScrollContainerView {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        private var viewModel: ItemViewModel

        private let content: Content

        init(
            viewModel: ItemViewModel,
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
            self.viewModel = viewModel
        }

        @ViewBuilder
        private var shelfView: some View {
            VStack(alignment: .center, spacing: 10) {
                if let parentTitle = viewModel.item.parentTitle {
                    Text(parentTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                }

                Text(viewModel.item.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)

                DotHStack {
                    if let seasonEpisodeLabel = viewModel.item.seasonEpisodeLabel {
                        Text(seasonEpisodeLabel)
                    }

                    if let productionYear = viewModel.item.premiereDateYear {
                        Text(productionYear)
                    }

                    if let runtime = viewModel.item.runTimeLabel {
                        Text(runtime)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

                ItemView.AttributesHStack(viewModel: viewModel, alignment: .center)

                Group {
                    if viewModel.presentPlayButton {
                        ItemView.PlayButton(viewModel: viewModel)
                            .frame(height: 50)
                    }

                    ItemView.ActionButtonHStack(viewModel: viewModel)
                        .font(.title)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: 300)
            }
        }

        private var imageType: ImageType {
            if viewModel.item.type == .episode {
                return .primary
            } else {
                return .backdrop
            }
        }

        @ViewBuilder
        private var header: some View {
            VStack(alignment: .center) {
                ImageView(viewModel.item.imageSource(imageType, maxWidth: 600))
                    .placeholder { source in
                        if let blurHash = source.blurHash {
                            BlurHashView(blurHash: blurHash, size: .Square(length: 8))
                        } else {
                            Color.secondarySystemFill
                                .opacity(0.75)
                        }
                    }
                    .failure {
                        SystemImageContentView(systemName: viewModel.item.systemImage)
                    }
                    .frame(maxHeight: 300)
                    .posterStyle(.landscape)
                    .posterShadow()
                    .padding(.horizontal)

                shelfView
            }
        }

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {

                    header

                    // MARK: Overview

                    ItemView.OverviewView(item: viewModel.item)
                        .overviewLineLimit(4)
                        .padding(.horizontal)

                    RowDivider()

                    // MARK: Genres

                    content
                        .edgePadding(.bottom)
                }
            }
        }
    }
}
