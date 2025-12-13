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

        @ObservedObject
        private var viewModel: ItemViewModel

        @State
        private var globalSize: CGSize = .zero

        #if !os(tvOS)
        @Environment(\.horizontalSizeClass)
        private var horizontalSizeClass
        #endif

        private let content: Content

        init(
            viewModel: ItemViewModel,
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
            self.viewModel = viewModel
        }

        // MARK: - Layout Properties

        private var isPerson: Bool {
            viewModel.item.type == .person || viewModel.item.type == .musicArtist
        }

        private var useHorizontalLayout: Bool {
            #if os(tvOS)
            true
            #else
            UIDevice.isPad && horizontalSizeClass != .compact
            #endif
        }

        private var heightRatio: CGFloat {
            #if os(tvOS)
            1.0
            #else
            useHorizontalLayout ? (globalSize.isLandscape ? 0.75 : 0.5) : 0.75
            #endif
        }

        // MARK: - Header Properties

        private var headerItem: BaseItemDto {
            if isPerson,
               let typeViewModel = viewModel as? CollectionItemViewModel,
               let randomItem = typeViewModel.randomItem()
            {
                return randomItem
            }
            return viewModel.item
        }

        private var imageType: ImageType {
            switch viewModel.item.type {
            case .episode, .musicVideo, .video:
                .primary
            default:
                usePrimaryImage ? .primary : .backdrop
            }
        }

        private var headerImageSource: ImageSource {
            headerItem.imageSource(
                imageType,
                maxWidth: 1920
            )
        }

        #if !os(tvOS)
        private var headerBottomColor: Color {
            headerItem.blurHash(for: imageType)?.averageLinearColor ?? Color.secondarySystemFill
        }
        #endif

        // MARK: - Body

        var body: some View {
            OffsetScrollView(heightRatio: heightRatio) {
                headerView
            } overlay: {
                overlayView
                    .frame(maxWidth: .infinity)
                #if !os(tvOS)
                    .edgePadding(useHorizontalLayout ? .all : .horizontal)
                    .edgePadding(useHorizontalLayout ? .init() : .bottom)
                #endif
            } content: {
                content
                    .padding(.top, 10)
                    .edgePadding(.bottom)
            }
            .trackingSize($globalSize)
        }

        // MARK: - Header View

        @ViewBuilder
        private var headerView: some View {
            #if os(tvOS)
            ImageView(headerImageSource)
                .id(headerImageSource.url?.hashValue)
                .animation(.linear(duration: 0.1), value: headerImageSource.url?.hashValue)
            #else
            headerImage
                .id(headerImageSource.url?.hashValue)
                .animation(.linear(duration: 0.1), value: headerImageSource.url?.hashValue)
            #endif
        }

        #if !os(tvOS)
        @ViewBuilder
        private var headerImage: some View {
            if useHorizontalLayout {
                ImageView(headerImageSource)
                    .aspectRatio(1.77, contentMode: .fill)
                    .bottomEdgeGradient(bottomColor: headerBottomColor)
            } else {
                GeometryReader { proxy in
                    if !proxy.size.height.isZero {
                        ImageView(viewModel.item.imageSource(
                            imageType,
                            maxWidth: usePrimaryImage ? proxy.size.width : 0,
                            maxHeight: usePrimaryImage ? 0 : proxy.size.height * 0.6
                        ))
                        .aspectRatio(usePrimaryImage ? (2 / 3) : 1.77, contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.6)
                        .bottomEdgeGradient(bottomColor: headerBottomColor)
                    }
                }
            }
        }
        #endif

        // MARK: - Overlay View

        @ViewBuilder
        private var overlayView: some View {
            if useHorizontalLayout {
                HorizontalOverlayView(viewModel: viewModel)
            } else {
                VerticalOverlayView(viewModel: viewModel, usePrimaryImage: usePrimaryImage)
            }
        }
    }
}
