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

        private var imageType: ImageType {
            switch viewModel.item.type {
            case .episode, .musicVideo, .video:
                .primary
            default:
                usePrimaryImage ? .primary : .backdrop
            }
        }

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

        private var overlayOffset: CGFloat {
            #if os(tvOS)
            isPerson ? 50 : 150
            #else
            0
            #endif
        }

        // MARK: - Header

        private var headerItem: BaseItemDto {
            if isPerson,
               let typeViewModel = viewModel as? CollectionItemViewModel,
               let randomItem = typeViewModel.randomItem()
            {
                return randomItem
            }
            return viewModel.item
        }

        private var headerImageSource: ImageSource {
            headerItem.imageSource(
                imageType,
                maxWidth: min(CGFloat(UIScreen.main.nativeBounds.width), 2160)
            )
        }

        private var headerBottomColor: Color {
            headerItem.blurHash(for: imageType)?.averageLinearColor ?? Color.secondarySystemFill
        }

        @ViewBuilder
        private var headerView: some View {
            #if os(tvOS)
            ImageView(headerImageSource)
                .id(headerImageSource.url?.hashValue)
                .animation(.linear(duration: 0.1), value: headerImageSource.url?.hashValue)
            #else
            iOSHeaderImage(source: headerImageSource, bottomColor: headerBottomColor)
                .id("\(globalSize.width)")
                .animation(.linear(duration: 0.1), value: headerImageSource.url?.hashValue)
            #endif
        }

        #if !os(tvOS)
        @ViewBuilder
        private func iOSHeaderImage(source: ImageSource, bottomColor: Color) -> some View {
            if useHorizontalLayout {
                ImageView(source)
                    .aspectRatio(1.77, contentMode: .fill)
                    .bottomEdgeGradient(bottomColor: bottomColor)
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
                        .bottomEdgeGradient(bottomColor: bottomColor)
                    }
                }
            }
        }
        #endif

        // MARK: - Overlay

        @ViewBuilder
        private var overlayView: some View {
            if useHorizontalLayout {
                HorizontalOverlayView(viewModel: viewModel)
            } else {
                VerticalOverlayView(viewModel: viewModel, usePrimaryImage: usePrimaryImage)
            }
        }

        #if !os(tvOS)
        @ViewBuilder
        private var overlayBackground: some View {
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
        }
        #endif

        // MARK: - Body

        var body: some View {
            OffsetScrollView(
                heightRatio: heightRatio,
                overlayOffset: overlayOffset
            ) {
                headerView
            } overlay: {
                overlayContent
            } content: {
                content
                    .padding(.top, 10)
                    .edgePadding(.bottom)
            }
            .trackingSize($globalSize)
        }

        @ViewBuilder
        private var overlayContent: some View {
            #if os(tvOS)
            overlayView
                .frame(maxWidth: .infinity)
            #else
            overlayView
                .id("\(globalSize.width)")
                .edgePadding(useHorizontalLayout ? .all : .horizontal)
                .edgePadding(useHorizontalLayout ? .init() : .bottom)
                .frame(maxWidth: .infinity)
                .background { overlayBackground }
            #endif
        }
    }
}
