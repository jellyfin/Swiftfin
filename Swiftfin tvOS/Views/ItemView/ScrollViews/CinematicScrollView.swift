//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct CinematicScrollView<Content: View>: ScrollContainerView {

        @ObservedObject
        private var viewModel: ItemViewModel

        @StateObject
        private var focusGuide = FocusGuide()

        private let content: Content

        init(
            viewModel: ItemViewModel,
            content: @escaping () -> Content
        ) {
            self.viewModel = viewModel
            self.content = content()
        }

        private func withBackgroundImageSource(
            @ViewBuilder content: @escaping (ImageSource) -> some View
        ) -> some View {
            let item: BaseItemDto

            if viewModel.item.type == .person || viewModel.item.type == .musicArtist,
               let typeViewModel = viewModel as? CollectionItemViewModel,
               let randomItem = typeViewModel.randomItem()
            {
                item = randomItem
            } else {
                item = viewModel.item
            }

            let imageType: ImageType = {
                switch item.type {
                case .episode, .musicVideo, .video:
                    .primary
                default:
                    .backdrop
                }
            }()

            let imageSource = item.imageSource(imageType, maxWidth: 1920)

            return content(imageSource)
                .id(imageSource.url?.hashValue)
                .animation(.linear(duration: 0.1), value: imageSource.url?.hashValue)
        }

        var body: some View {
            GeometryReader { proxy in
                ZStack {
                    withBackgroundImageSource { imageSource in
                        ImageView(imageSource)
                    }

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            CinematicHeaderView(viewModel: viewModel)
                                .ifLet(viewModel as? SeriesItemViewModel) { view, _ in
                                    view
                                        .focusGuide(
                                            focusGuide,
                                            tag: "header",
                                            bottom: "belowHeader"
                                        )
                                }
                                .frame(height: proxy.size.height - 150)
                                .padding(.bottom, 50)

                            content
                        }
                        .background {
                            BlurView(style: .dark)
                                .mask {
                                    VStack(spacing: 0) {
                                        LinearGradient(gradient: Gradient(stops: [
                                            .init(color: .white, location: 0),
                                            .init(color: .white.opacity(0.7), location: 0.4),
                                            .init(color: .white.opacity(0), location: 1),
                                        ]), startPoint: .bottom, endPoint: .top)
                                            .frame(height: proxy.size.height - 150)

                                        Color.white
                                    }
                                }
                        }
                        .environmentObject(focusGuide)
                    }
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
            case actionButtons
        }

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @Router
        private var router
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
                            maxHeight: 250
                        ))
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
                        .padding(.bottom)

                        OverviewView(item: viewModel.item)
                            .taglineLineLimit(1)
                            .overviewLineLimit(3)

                        if viewModel.item.type != .person {
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

                                ItemView.AttributesHStack(
                                    attributes: attributes,
                                    viewModel: viewModel
                                )
                            }
                        }
                    }

                    Spacer()

                    VStack(spacing: 30) {
                        if viewModel.item.type == .person || viewModel.item.type == .musicArtist {
                            ImageView(viewModel.item.imageSource(.primary, maxWidth: 450))
                                .failure {
                                    SystemImageContentView(systemName: viewModel.item.systemImage)
                                }
                                .posterStyle(.portrait, contentMode: .fill)
                                .cornerRadius(10)
                                .accessibilityIgnoresInvertColors()
                        } else if viewModel.item.presentPlayButton {
                            ItemView.PlayButton(viewModel: viewModel)
                                .focused($focusedLayer, equals: .playButton)
                                .frame(height: 100)
                        }
                        ItemView.ActionButtonHStack(viewModel: viewModel)
                            .focused($focusedLayer, equals: .actionButtons)
                            .frame(height: 100)
                    }
                    .frame(width: 450)
                    .padding(.leading, 150)
                }
            }
            .padding(.horizontal, 50)
            .onChange(of: focusedLayer) { _, layer in
                if layer == .top {
                    if viewModel.item.presentPlayButton {
                        focusedLayer = .playButton
                    } else {
                        focusedLayer = .actionButtons
                    }
                }
            }
        }
    }
}
