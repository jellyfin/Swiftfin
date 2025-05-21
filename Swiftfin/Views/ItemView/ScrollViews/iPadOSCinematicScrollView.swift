//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: remove rest occurrences of `UIDevice.main` sizings
// TODO: overlay spacing between overview and play button should be dynamic
//       - smaller spacing on smaller widths (iPad Mini, portrait)

// landscape vs portrait ratios just "feel right". Adjust if necessary
// or if a concrete design comes along.

extension ItemView {

    struct iPadOSCinematicScrollView<Content: View>: ScrollContainerView {

        @ObservedObject
        private var viewModel: ItemViewModel

        @State
        private var globalSize: CGSize = .zero

        private let content: Content

        init(
            viewModel: ItemViewModel,
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
            self.viewModel = viewModel
        }

        private var imageType: ImageType {
            if viewModel.item.type == .episode {
                return .primary
            } else {
                return .backdrop
            }
        }

        var body: some View {
            OffsetScrollView(
                headerHeight: globalSize.isLandscape ? 0.75 : 0.6
            ) {
                ImageView(viewModel.item.imageSource(.backdrop, maxWidth: 1920))
                    .aspectRatio(1.77, contentMode: .fill)
            } overlay: {
                VStack(spacing: 0) {
                    Spacer()

                    OverlayView(viewModel: viewModel)
                        .edgePadding()
                }
                .background {
                    BlurView(style: .systemThinMaterialDark)
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.4),
                                    .init(color: .white, location: 0.8),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                }
            } content: {
                content
                    .edgePadding(.vertical)
            }
            .trackingSize($globalSize)
        }
    }
}

extension ItemView.iPadOSCinematicScrollView {

    struct OverlayView: View {

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            HStack(alignment: .bottom) {

                VStack(alignment: .leading, spacing: 20) {

                    ImageView(viewModel.item.imageSource(
                        .logo,
                        maxWidth: UIScreen.main.bounds.width * 0.4,
                        maxHeight: 130
                    ))
                    .placeholder { _ in
                        EmptyView()
                    }
                    .failure {
                        Text(viewModel.item.displayTitle)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.4, maxHeight: 130, alignment: .bottomLeading)

                    ItemView.OverviewView(item: viewModel.item)
                        .overviewLineLimit(3)
                        .taglineLineLimit(2)
                        .foregroundColor(.white)

                    HStack(spacing: 30) {
                        DotHStack {
                            if let firstGenre = viewModel.item.genres?.first {
                                Text(firstGenre)
                            }

                            if let premiereYear = viewModel.item.premiereDateYear {
                                Text(premiereYear)
                            }

                            if let playButtonitem = viewModel.playButtonItem, let runtime = playButtonitem.runTimeLabel {
                                Text(runtime)
                            }
                        }
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.lightGray))

                        ItemView.AttributesHStack(viewModel: viewModel, alignment: .leading)
                    }
                }
                .padding(.trailing, 200)

                Spacer()

                VStack(spacing: 10) {
                    if viewModel.presentPlayButton {
                        ItemView.PlayButton(viewModel: viewModel)
                            .frame(height: 50)
                    }

                    ItemView.ActionButtonHStack(viewModel: viewModel)
                        .font(.title)
                        .foregroundColor(.white)
                }
                .frame(width: 250)
            }
        }
    }
}
