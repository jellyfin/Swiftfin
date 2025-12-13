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

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @ObservedObject
        var viewModel: ItemViewModel

        #if os(tvOS)
        @FocusState
        private var focusedLayer: FocusLayer?

        private enum FocusLayer: Hashable {
            case top
            case playButton
            case actionButtons
        }
        #endif

        // MARK: - Layout Constants

        private var buttonHeight: CGFloat {
            #if os(tvOS)
            100
            #else
            50
            #endif
        }

        private var buttonSpacing: CGFloat {
            #if os(tvOS)
            25
            #else
            10
            #endif
        }

        private let buttonWidthRatio: CGFloat = 0.30
        private let logoWidthRatio: CGFloat = 0.35

        private var logoHeightRatio: CGFloat {
            #if os(tvOS)
            0.5
            #else
            0.25
            #endif
        }

        private var isPerson: Bool {
            viewModel.item.type == .person || viewModel.item.type == .musicArtist
        }

        var body: some View {
            GeometryReader { geometry in
                let buttonWidth = geometry.size.width * buttonWidthRatio
                let logoMaxWidth = geometry.size.width * logoWidthRatio
                let logoMaxHeight = geometry.size.height * logoHeightRatio

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

                        trailingContent(buttonWidth: buttonWidth)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .bottom)
            }
            #if os(tvOS)
            .onChange(of: focusedLayer) { _, layer in
                guard layer == .top else { return }
                focusedLayer = (viewModel.item.presentPlayButton && !isPerson) ? .playButton : .actionButtons
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
                ImageView(viewModel.item.imageSource(.logo, maxWidth: logoMaxWidth, maxHeight: logoMaxHeight))
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
                        ItemView.AttributesHStack(attributes: attributes, viewModel: viewModel)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .edgePadding(.trailing)
        }

        @ViewBuilder
        private func trailingContent(buttonWidth: CGFloat) -> some View {

            let personWidth = buttonWidth * 2 / 3

            VStack(spacing: buttonSpacing) {
                if isPerson {
                    personContent(personImageWidth: personWidth)
                } else if viewModel.item.presentPlayButton {
                    playButtonContent()
                } else {
                    actionButtonsContent(buttonWidth: buttonWidth)
                }
            }
            .frame(width: isPerson ? personWidth : buttonWidth)
        }

        // MARK: - Person Content

        @ViewBuilder
        private func personContent(personImageWidth: CGFloat) -> some View {
            PosterImage(
                item: viewModel.item,
                type: .portrait,
                contentMode: UIDevice.isTV ? .fill : .fit,
                maxWidth: personImageWidth
            )
            .posterCornerRadius(.portrait)
            .posterShadow()
            .cornerRadius(10)
            .frame(width: personImageWidth)

            ItemView.ActionButtonHStack(viewModel: viewModel)
                .foregroundStyle(.white)
                .frame(width: personImageWidth, height: buttonHeight)
            #if os(tvOS)
                .focused($focusedLayer, equals: .actionButtons)
            #endif
        }

        // MARK: - Play Button Content

        @ViewBuilder
        private func playButtonContent() -> some View {
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
