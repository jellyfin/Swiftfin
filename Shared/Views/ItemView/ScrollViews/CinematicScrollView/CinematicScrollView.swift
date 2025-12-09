//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct CinematicScrollView<Content: View>: View, ScrollContainerView {

        @Default(.Customization.CinematicItemViewType.usePrimaryImage)
        private var usePrimaryImage

        @Environment(\.horizontalSizeClass)
        private var horizontalSizeClass

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
            switch viewModel.item.type {
            case .episode, .musicVideo, .video:
                .primary
            default:
                #if os(tvOS)
                .backdrop
                #else
                usePrimaryImage ? .primary : .backdrop
                #endif
            }
        }

        private func withHeaderImageItem(
            @ViewBuilder content: @escaping (ImageSource, Color) -> some View
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

            let bottomColor = item.blurHash(for: imageType)?.averageLinearColor ?? Color.secondarySystemFill

            #if os(tvOS)
            let maxWidth: CGFloat = 2160
            #else
            let maxWidth = min(CGFloat(UIScreen.main.nativeBounds.width), 3840)
            #endif

            let imageSource = item.imageSource(imageType, maxWidth: maxWidth)

            return content(imageSource, bottomColor)
                .id(imageSource.url?.hashValue)
                .animation(.linear(duration: 0.1), value: imageSource.url?.hashValue)
        }

        private var useHorizontalLayout: Bool {
            #if os(tvOS)
            true
            #else
            UIDevice.isPad && horizontalSizeClass != .compact
            #endif
        }

        private var isPerson: Bool {
            viewModel.item.type == .person || viewModel.item.type == .musicArtist
        }

        @ViewBuilder
        private var headerView: some View {
            withHeaderImageItem { imageSource, bottomColor in
                #if os(tvOS)
                ImageView(imageSource)
                #else
                if useHorizontalLayout {
                    ImageView(imageSource)
                        .aspectRatio(1.77, contentMode: .fill)
                        .bottomEdgeGradient(bottomColor: bottomColor)
                } else {
                    GeometryReader { proxy in
                        if proxy.size.height.isZero {
                            EmptyView()
                        } else {
                            ImageView(viewModel.item.imageSource(
                                imageType,
                                maxWidth: usePrimaryImage ? proxy.size.width : 0,
                                maxHeight: usePrimaryImage ? 0 : proxy.size.height * 0.6
                            ))
                            .aspectRatio(usePrimaryImage ? (2 / 3) : 1.77, contentMode: .fill)
                            .frame(width: proxy.size.width, height: proxy.size.height * 0.6)
                            .bottomEdgeGradient(bottomColor: bottomColor)
                        }
                    }
                }
                #endif
            }
        }

        @ViewBuilder
        private var overlayView: some View {
            if useHorizontalLayout {
                HorizontalOverlayView(viewModel: viewModel)
                    .id(globalSize)
            } else {
                VerticalOverlayView(viewModel: viewModel, usePrimaryImage: usePrimaryImage)
                    .id(globalSize)
            }
        }

        @ViewBuilder
        private var overlayBackground: some View {
            #if os(tvOS)
            EmptyView()
            #else
            BlurView(style: .systemThinMaterialDark)
                .maskLinearGradient {
                    if useHorizontalLayout {
                        (location: 0.4, opacity: 0)
                        (location: 0.8, opacity: 1)
                    } else {
                        (location: 0, opacity: 0)
                        (location: 0.3, opacity: 1)
                        (location: 1, opacity: 1)
                    }
                }
            #endif
        }

        private var heightRatio: CGFloat {
            #if os(tvOS)
            1.0
            #else
            useHorizontalLayout ? (globalSize.isLandscape ? 0.75 : 0.5) : 0.75
            #endif
        }

        private var overlayOffset: CGFloat {
            #if os(tvOS)
            isPerson ? 50 : 150
            #else
            0
            #endif
        }

        var body: some View {
            OffsetScrollView(
                heightRatio: heightRatio,
                overlayOffset: overlayOffset
            ) {
                headerView
            } overlay: {
                overlayView
                #if os(iOS)
                .edgePadding(useHorizontalLayout ? .all : .horizontal)
                .edgePadding(useHorizontalLayout ? .init() : .bottom)
                #endif
                .frame(maxWidth: .infinity)
                .background { overlayBackground }
            } content: {
                content
                    .padding(.top, 10)
                    .edgePadding(.bottom)
            }
            .trackingSize($globalSize)
        }
    }
}
