//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct iPadOSPersonScrollView<Content: View>: ScrollContainerView {

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

        @ViewBuilder
        private var headerView: some View {
            let personViewModel = viewModel as! PersonItemViewModel
            if let randomElement = personViewModel.personItems.elements.randomElement(),
               let randomValue = randomElement.value.randomElement()
            {
                ImageView(randomValue.imageSource(
                    randomValue.type == .episode ? .primary : .backdrop,
                    maxWidth: 1920
                ))
                .aspectRatio(1.77, contentMode: .fill)
            }
        }

        var body: some View {
            OffsetScrollView(
                headerHeight: globalSize.isLandscape ? 0.75 : 0.6
            ) {
                headerView
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

extension ItemView.iPadOSPersonScrollView {

    struct OverlayView: View {

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            HStack(alignment: .bottom) {

                VStack(alignment: .leading, spacing: 20) {

                    Text(viewModel.item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.white)

                    ItemView.OverviewView(item: viewModel.item)
                        .overviewLineLimit(3)
                        .taglineLineLimit(2)
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        let items = [
                            viewModel.item.premiereDate?.formatted(date: .long, time: .omitted),
                            viewModel.item.premiereDate?.formatted(.age.death(viewModel.item.endDate)),
                            viewModel.item.endDate?.formatted(date: .long, time: .omitted),
                            viewModel.item.productionLocations?.first,
                        ].compactMap { $0 }

                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            Text(item)
                                .font(.subheadline.weight(.medium))

                            if index < items.count - 1 {
                                Text("•")
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        Spacer()
                    }
                    .foregroundColor(.secondary)
                }
                .padding(.trailing)

                Spacer()

                VStack(spacing: 10) {
                    ImageView(viewModel.item.imageSource(.primary, maxWidth: 200))
                        .failure {
                            SystemImageContentView(systemName: viewModel.item.systemImage)
                        }
                        .posterStyle(.portrait, contentMode: .fit)
                        .frame(width: 200)
                        .accessibilityIgnoresInvertColors()

                    ItemView.ActionButtonHStack(viewModel: viewModel)
                        .font(.title)
                        .foregroundColor(.white)
                }
                .frame(width: 200)
            }
        }
    }
}
