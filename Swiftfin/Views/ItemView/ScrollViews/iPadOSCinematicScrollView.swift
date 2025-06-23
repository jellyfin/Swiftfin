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
                /// Set a random image from a person's content
                if let personViewModel = viewModel as? PersonItemViewModel,
                   let randomType = personViewModel.personItems.elements.randomElement(),
                   let randomValue = randomType.value.elements.randomElement()
                {
                    ImageView(randomValue.imageSource(
                        randomValue.type == .episode ? .primary : .backdrop,
                        maxWidth: 1920
                    ))
                    .aspectRatio(1.77, contentMode: .fill)
                } else {
                    ImageView(viewModel.item.imageSource(imageType, maxWidth: 1920))
                        .aspectRatio(1.77, contentMode: .fill)
                }
            } overlay: {
                VStack(spacing: 0) {
                    Spacer()

                    OverlayView(viewModel: viewModel)
                        .edgePadding()
                }
                .background {
                    BlurView(style: .systemThinMaterialDark)
                        .maskLinearGradient {
                            (location: 0.4, opacity: 0)
                            (location: 0.8, opacity: 1)
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

        @StoredValue(.User.itemViewAttributes)
        private var attributes

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

                            if let personViewModel = viewModel as? PersonItemViewModel {

                                if let birthday = personViewModel.item.premiereDate?.formatted(date: .numeric, time: .omitted) {
                                    Text(birthday)
                                }

                                if let deathday = personViewModel.item.endDate?.formatted(date: .numeric, time: .omitted) {
                                    Text(deathday)
                                }

                                if let age = personViewModel.item.premiereDate?.formatted(.age.death(viewModel.item.endDate)) {
                                    Text(age)
                                }

                                if let birthPlace = personViewModel.item.productionLocations?.first {
                                    Text(birthPlace)
                                }
                            } else {

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
                        }
                        .font(.footnote)
                        .foregroundColor(Color(UIColor.lightGray))

                        ItemView.AttributesHStack(
                            attributes: attributes,
                            viewModel: viewModel,
                            alignment: .leading
                        )
                    }
                }
                .padding(.trailing, 200)

                Spacer()

                VStack(spacing: 10) {
                    if let personViewModel = viewModel as? PersonItemViewModel {
                        ImageView(personViewModel.item.imageSource(.primary, maxWidth: 200))
                            .failure {
                                SystemImageContentView(systemName: viewModel.item.systemImage)
                            }
                            .posterStyle(.portrait, contentMode: .fit)
                            .frame(width: 200)
                            .accessibilityIgnoresInvertColors()
                    } else if viewModel.presentPlayButton {
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
