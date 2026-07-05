//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct SimpleScrollView<Content: View>: ScrollContainerView {

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @Router
        private var router

        @ObservedObject
        private var provider: ItemContentGroupProvider

        private let content: Content

        init(
            provider: ItemContentGroupProvider,
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
            self.provider = provider
        }

        @ViewBuilder
        private var shelfView: some View {
            VStack(alignment: .center, spacing: 10) {
                if let parentTitle = provider.item.parentTitle {
                    Text(parentTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)
                        .foregroundColor(.secondary)
                }

                Text(provider.item.displayTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)

                DotHStack {
                    if let seasonEpisodeLabel = provider.item.seasonEpisodeLabel {
                        Text(seasonEpisodeLabel)
                    }

                    if let productionYear = provider.item.premiereDateYear {
                        Text(productionYear)
                    }

                    if let runtime = provider.item.runTimeLabel {
                        Text(runtime)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)

                Group {
                    ItemView.AttributesHStack(
                        attributes: attributes,
                        item: provider.item,
                        selectedMediaSource: provider.selectedMediaSource,
                        alignment: .center
                    )

                    if provider.item.presentPlayButton {
                        ItemView.PlayButton(provider: provider)
                            .frame(height: 50)
                    }

                    ItemView.ActionButtonHStack(provider: provider)
                        .frame(height: 50)
                }
                .frame(maxWidth: 300)
            }
        }

        // TODO: remove and just use `PosterImage` with landscape
        //       after poster environment implemented
        private var imageType: ImageType {
            switch provider.item.type {
            case .episode, .musicVideo, .video:
                .primary
            default:
                .backdrop
            }
        }

        @ViewBuilder
        private var header: some View {
            VStack(alignment: .center) {
                ZStack {
                    Rectangle()
                        .fill(.complexSecondary)

                    ImageView(provider.item.imageSource(imageType, environment: ImageSourceOptions(maxWidth: 600)))
                        .failure {
                            SystemImageContentView(systemName: provider.item.systemImage)
                        }
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

                    ItemView.OverviewView(item: provider.item)
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
