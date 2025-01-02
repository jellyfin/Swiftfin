//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension ItemView {

    struct CinematicScrollView<Content: View>: View {

        @ObservedObject
        var viewModel: ItemViewModel

        let content: () -> Content

        var body: some View {
            ZStack {
                if viewModel.item.type == .episode {
                    ImageView(viewModel.item.imageSource(.primary, maxWidth: 1920))
                } else {
                    ImageView(viewModel.item.imageSource(.backdrop, maxWidth: 1920))
                }

                ScrollView(.vertical, showsIndicators: false) {
                    content()
                }
            }
            .ignoresSafeArea()
        }
    }
}

extension ItemView {

    struct CinematicHeaderView: View {

        enum CinematicHeaderFocusLayer: Hashable {
            case top
            case playButton
        }

        @EnvironmentObject
        private var router: ItemCoordinator.Router
        @ObservedObject
        var viewModel: ItemViewModel
        @FocusState
        private var focusedLayer: CinematicHeaderFocusLayer?

        var body: some View {
            VStack(alignment: .leading) {

                Color.clear
                    .focusable()
                    .focused($focusedLayer, equals: .top)

                HStack(alignment: .bottom) {

                    VStack(alignment: .leading, spacing: 20) {

                        ImageView(viewModel.item.imageSource(
                            .logo,
                            maxWidth: UIScreen.main.bounds.width * 0.4,
                            maxHeight: 250
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
                        .padding(.bottom)
                        .frame(maxHeight: 250, alignment: .bottomLeading)

                        if let tagline = viewModel.item.taglines?.first {
                            Text(tagline)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                        }

                        Text(viewModel.item.overview ?? L10n.noOverviewAvailable)
                            .font(.subheadline)
                            .lineLimit(3)

                        HStack {

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
                            .font(.caption)
                            .foregroundColor(Color(UIColor.lightGray))

                            ItemView.AttributesHStack(viewModel: viewModel)
                        }
                    }

                    Spacer()

                    VStack {
                        ItemView.PlayButton(viewModel: viewModel)
                            .focused($focusedLayer, equals: .playButton)

                        ItemView.ActionButtonHStack(viewModel: viewModel)
                            .frame(width: 400)
                    }
                    .frame(width: 450)
                    .padding(.leading, 150)
                }
            }
            .padding(.horizontal, 50)
            .onChange(of: focusedLayer) { _, layer in
                if layer == .top {
                    focusedLayer = .playButton
                }
            }
        }
    }
}
