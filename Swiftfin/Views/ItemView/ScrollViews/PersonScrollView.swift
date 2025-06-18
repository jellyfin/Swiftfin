//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import SwiftUI

extension ItemView {

    struct PersonScrollView<Content: View>: ScrollContainerView {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        private var viewModel: ItemViewModel

        private let blurHashBottomEdgeColor: Color
        private let content: Content

        init(
            viewModel: ItemViewModel,
            content: @escaping () -> Content
        ) {
            if let backdropBlurHash = viewModel.item.blurHash(.backdrop) {
                let bottomRGB = BlurHash(string: backdropBlurHash)!.averageLinearRGB
                blurHashBottomEdgeColor = Color(
                    red: Double(bottomRGB.0),
                    green: Double(bottomRGB.1),
                    blue: Double(bottomRGB.2)
                )
            } else {
                blurHashBottomEdgeColor = Color.secondarySystemFill
            }

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
                    maxWidth: UIScreen.main.bounds.width
                ))
                .aspectRatio(1.77, contentMode: .fill)
                .frame(height: UIScreen.main.bounds.height * 0.35)
                .bottomEdgeGradient(bottomColor: blurHashBottomEdgeColor)
            }
        }

        var body: some View {
            OffsetScrollView(headerHeight: 0.45) {
                headerView
            } overlay: {
                VStack {
                    Spacer()

                    OverlayView(viewModel: viewModel)
                        .edgePadding(.horizontal)
                        .edgePadding(.bottom)
                        .background {
                            BlurView(style: .systemThinMaterialDark)
                                .maskLinearGradient {
                                    (location: 0.2, opacity: 0)
                                    (location: 0.3, opacity: 0.5)
                                    (location: 0.55, opacity: 1)
                                }
                        }
                }
            } content: {
                VStack(alignment: .leading, spacing: 10) {

                    ItemView.OverviewView(item: viewModel.item)
                        .overviewLineLimit(4)
                        .taglineLineLimit(2)
                        .padding(.horizontal)

                    RowDivider()

                    content
                }
                .edgePadding(.vertical)
            }
        }
    }
}

extension ItemView.PersonScrollView {

    struct OverlayView: View {

        @StoredValue(.User.itemViewAttributes)
        private var attributes

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        @ViewBuilder
        private var rightShelfView: some View {
            VStack(alignment: .leading) {

                Text(viewModel.item.displayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                FlowLayout(
                    alignment: .leading,
                    direction: .down,
                    spacing: 8,
                    lineSpacing: 0,
                    minRowLength: 1
                ) {
                    let items = [
                        viewModel.item.premiereDate?.formatted(date: .numeric, time: .omitted),
                        viewModel.item.endDate?.formatted(date: .numeric, time: .omitted),
                    ].compactMap { $0 }

                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        Text(item)

                        if index < items.count - 1 {
                            Text("•")
                        }
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)

                if let age = viewModel.item.premiereDate?.formatted(.age.death(viewModel.item.endDate)) {
                    Text(age)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }

                if let birthPlace = viewModel.item.productionLocations?.first {
                    Text(birthPlace)
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.secondary)
                }
            }
        }

        var body: some View {
            HStack(alignment: .bottom, spacing: 12) {

                ImageView(viewModel.item.imageSource(.primary, maxWidth: 130))
                    .failure {
                        SystemImageContentView(systemName: viewModel.item.systemImage)
                    }
                    .posterStyle(.portrait, contentMode: .fit)
                    .frame(width: 130)
                    .accessibilityIgnoresInvertColors()

                VStack(alignment: .leading, spacing: 10) {
                    rightShelfView
                    ItemView.ActionButtonHStack(viewModel: viewModel, equalSpacing: true)
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
    }
}
