//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView.CinematicScrollView {

    struct HorizontalOverlayView: View {

        #if os(tvOS)
        private enum FocusLayer: Hashable {
            case top
            case playButton
            case actionButtons
        }

        @FocusState
        private var focusedLayer: FocusLayer?
        #endif

        private let buttonHeight: CGFloat = UIDevice.isTV ? 100 : 50
        private let buttonSpacing: CGFloat = UIDevice.isTV ? 25 : 10

        private let buttonWidthRatio: CGFloat = 0.25

        private let logoWidthRatio: CGFloat = 0.35
        private let logoHeightRatio: CGFloat = UIDevice.isTV ? 0.5 : 0.25

        private let personImageAspectRatio: CGFloat = 1.5

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @ObservedObject
        var viewModel: ItemViewModel

        init(viewModel: ItemViewModel) {
            self.viewModel = viewModel
        }

        private var isPerson: Bool {
            viewModel.item.type == .person || viewModel.item.type == .musicArtist
        }

        var body: some View {
            GeometryReader { geometry in
                let buttonWidth = geometry.size.width * buttonWidthRatio
                let logoMaxWidth = geometry.size.width * logoWidthRatio
                let logoMaxHeight = geometry.size.height * logoHeightRatio
                let personImageHeight = min(
                    buttonWidth * personImageAspectRatio,
                    geometry.size.height - buttonHeight - buttonSpacing
                )

                VStack(alignment: .leading) {
                    #if os(tvOS)
                    Color.clear
                        .focusable()
                        .focused($focusedLayer, equals: .top)
                    #endif

                    HStack(alignment: .bottom) {
                        leadingContent(
                            logoMaxWidth: logoMaxWidth,
                            logoMaxHeight: logoMaxHeight
                        )

                        trailingContent(
                            buttonWidth: buttonWidth,
                            personImageHeight: personImageHeight
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            #if os(tvOS)
            .onChange(of: focusedLayer) { _, layer in
                if layer == .top {
                    if viewModel.item.presentPlayButton && !isPerson {
                        focusedLayer = .playButton
                    } else {
                        focusedLayer = .actionButtons
                    }
                }
            }
            #endif
        }

        // MARK: - Leading Content

        @ViewBuilder
        private func leadingContent(
            logoMaxWidth: CGFloat,
            logoMaxHeight: CGFloat
        ) -> some View {
            VStack(alignment: .leading, spacing: 10) {

                ImageView(viewModel.item.imageSource(
                    .logo,
                    maxWidth: logoMaxWidth,
                    maxHeight: logoMaxHeight
                ))
                .image { image in
                    image
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: logoMaxWidth, maxHeight: logoMaxHeight, alignment: .bottomLeading)
                }
                .placeholder { _ in
                    EmptyView()
                }
                .failure {
                    Marquee(viewModel.item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }

                ItemView.OverviewView(item: viewModel.item)
                    .overviewLineLimit(3)
                    .taglineLineLimit(1)
                    .foregroundStyle(.white)

                if !isPerson {
                    HStack {
                        MetadataView(viewModel: viewModel)

                        ItemView.AttributesHStack(
                            attributes: attributes,
                            viewModel: viewModel
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .edgePadding(.trailing)
        }

        // MARK: - Trailing Content

        @ViewBuilder
        private func trailingContent(
            buttonWidth: CGFloat,
            personImageHeight: CGFloat
        ) -> some View {
            VStack(spacing: buttonSpacing) {
                if isPerson {
                    personContent(
                        personImageWidth: buttonWidth,
                        personImageHeight: personImageHeight
                    )
                } else if viewModel.item.presentPlayButton {
                    playButtonContent(buttonWidth: buttonWidth)
                } else {
                    actionButtonsContent(buttonWidth: buttonWidth)
                }
            }
            .frame(width: buttonWidth)
        }

        // MARK: - Person Content

        @ViewBuilder
        private func personContent(
            personImageWidth: CGFloat,
            personImageHeight: CGFloat
        ) -> some View {
            ImageView(viewModel.item.imageSource(
                .primary,
                maxWidth: personImageWidth
            ))
            .failure {
                SystemImageContentView(systemName: viewModel.item.systemImage)
            }
            .posterStyle(.portrait, contentMode: .fill)
            .frame(width: personImageWidth, height: personImageHeight)
            .cornerRadius(10)
            .accessibilityIgnoresInvertColors()

            ItemView.ActionButtonHStack(viewModel: viewModel)
                .foregroundStyle(.white)
                .frame(width: personImageWidth, height: buttonHeight)
            #if os(tvOS)
                .focused($focusedLayer, equals: .actionButtons)
            #endif
        }

        // MARK: - Play Button Content

        @ViewBuilder
        private func playButtonContent(buttonWidth: CGFloat) -> some View {
            ItemView.PlayButton(viewModel: viewModel)
                .frame(height: buttonHeight)
            #if os(tvOS)
                .focused($focusedLayer, equals: .playButton)
            #endif

            ItemView.ActionButtonHStack(viewModel: viewModel)
                .foregroundStyle(.white)
                .frame(height: buttonHeight)
            #if os(tvOS)
                .focused($focusedLayer, equals: .actionButtons)
            #endif
        }

        // MARK: - Action Buttons Content

        @ViewBuilder
        private func actionButtonsContent(buttonWidth: CGFloat) -> some View {
            ItemView.ActionButtonHStack(viewModel: viewModel)
                .foregroundStyle(.white)
                .frame(width: buttonWidth, height: buttonHeight)
            #if os(tvOS)
                .focused($focusedLayer, equals: .actionButtons)
            #endif
        }
    }
}
