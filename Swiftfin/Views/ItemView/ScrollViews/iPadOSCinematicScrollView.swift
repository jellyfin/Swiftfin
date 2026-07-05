//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct iPadOSCinematicScrollView<Content: View>: ScrollContainerView {

        @ObservedObject
        private var provider: ItemContentGroupProvider

        @State
        private var globalSize: CGSize = .zero

        @State
        private var bottomColor: Color?

        private let content: Content

        init(
            provider: ItemContentGroupProvider,
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
            self.provider = provider
        }

        private var imageType: ImageType {
            switch provider.item.type {
            case .episode, .musicVideo, .video:
                .primary
            default:
                .backdrop
            }
        }

        private func withHeaderImageItem(
            @ViewBuilder content: @escaping (ImageSource, Color?) -> some View
        ) -> some View {

            let item: BaseItemDto = if provider.item.type == .person || provider.item.type == .musicArtist,
                                       let randomItem = provider.randomBackdropItem
            {
                randomItem
            } else {
                provider.item
            }

            let imageSource = item.imageSource(imageType, environment: ImageSourceOptions(maxWidth: 1920))

            return content(imageSource, bottomColor)
                .id(imageSource.url?.hashValue)
                .onChange(of: imageSource.url) { _ in
                    bottomColor = nil
                }
                .animation(.linear(duration: 0.1), value: imageSource.url?.hashValue)
        }

        @ViewBuilder
        private var headerView: some View {
            withHeaderImageItem { imageSource, gradientColor in
                ImageView(imageSource)
                    .resolvedColor($bottomColor)
                    .aspectRatio(1.77, contentMode: .fill)
                    .bottomEdgeGradient(bottomColor: gradientColor ?? Color.secondarySystemFill)
            }
        }

        var body: some View {
            OffsetScrollView(
                heightRatio: globalSize.isLandscape ? 0.75 : 0.5
            ) {
                headerView
            } overlay: {
                OverlayView(provider: provider)
                    .edgePadding()
                    .frame(maxWidth: .infinity)
                    .background {
                        BlurView(style: .systemThinMaterialDark)
                            .maskLinearGradient {
                                (location: 0.4, opacity: 0)
                                (location: 0.8, opacity: 1)
                            }
                    }
            } content: {
                content
                    .padding(.top, 10)
                    .edgePadding(.bottom)
            }
            .trackingSize($globalSize)
        }
    }
}

extension ItemView.iPadOSCinematicScrollView {

    struct OverlayView: View {

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @ObservedObject
        var provider: ItemContentGroupProvider

        var body: some View {
            GeometryReader { geometry in
                HStack(alignment: .bottom) {

                    VStack(alignment: .leading, spacing: 20) {

                        ImageView(provider.item.imageSource(
                            .logo,
                            environment: ImageSourceOptions(maxHeight: 130)
                        ))
                        .placeholder { _ in
                            EmptyView()
                        }
                        .failure {
                            Text(provider.item.displayTitle)
                                .font(.largeTitle)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.white)
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width * 0.4, maxHeight: 130, alignment: .bottomLeading)

                        ItemView.OverviewView(item: provider.item)
                            .overviewLineLimit(3)
                            .taglineLineLimit(2)
                            .foregroundStyle(.white)

                        if provider.item.type != .person {
                            FlowLayout(
                                alignment: .leading,
                                direction: .down,
                                spacing: 30,
                                minRowLength: 1
                            ) {
                                DotHStack {
                                    if let firstGenre = provider.item.genres?.first {
                                        Text(firstGenre)
                                    }

                                    if let premiereYear = provider.item.premiereDateYear {
                                        Text(premiereYear)
                                    }

                                    if let playButtonitem = provider.playButtonItem, let runtime = playButtonitem.runTimeLabel {
                                        Text(runtime)
                                    }
                                }
                                .font(.footnote)
                                .foregroundStyle(Color(UIColor.lightGray))
                                .fixedSize(horizontal: true, vertical: false)

                                ItemView.AttributesHStack(
                                    attributes: attributes,
                                    item: provider.item,
                                    selectedMediaSource: provider.selectedMediaSource,
                                    alignment: .leading
                                )
                            }
                        }
                    }
                    .padding(.trailing, geometry.size.width * 0.05)

                    Spacer()

                    VStack(spacing: 10) {
                        if provider.item.type == .person || provider.item.type == .musicArtist {
                            ImageView(provider.item.imageSource(.primary, environment: ImageSourceOptions(maxWidth: 200)))
                                .failure {
                                    SystemImageContentView(systemName: provider.item.systemImage)
                                }
                                .posterStyle(.portrait, contentMode: .fit)
                                .frame(width: 200)
                                .accessibilityIgnoresInvertColors()
                        } else if provider.item.presentPlayButton {
                            ItemView.PlayButton(provider: provider)
                                .frame(height: 50)
                        }

                        ItemView.ActionButtonHStack(provider: provider)
                            .foregroundStyle(.white)
                            .frame(height: 50)
                    }
                    .frame(width: 250)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
    }
}
