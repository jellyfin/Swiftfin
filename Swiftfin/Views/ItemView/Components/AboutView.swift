//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct AboutView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(alignment: .leading) {
                L10n.about.text
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibility(addTraits: [.isHeader])
                    .padding(.horizontal)
                    .if(UIDevice.isIPad) { view in
                        view.padding(.horizontal)
                    }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ImageView(
                            viewModel.item.type == .episode ? viewModel.item.seriesImageSource(.primary, maxWidth: 300) : viewModel
                                .item.imageSource(.primary, maxWidth: 300)
                        )
                        .posterStyle(type: .portrait, width: 130)
                        .accessibilityIgnoresInvertColors()

                        Card(title: viewModel.item.displayTitle)
                            .content {
                                VStack(alignment: .leading, spacing: 10) {

                                    if let overview = viewModel.item.overview {
                                        Text(overview)
                                            .lineLimit(4)
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    } else {
                                        L10n.noOverviewAvailable.text
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .onSelect {
                                router.route(to: \.itemOverview, viewModel.item)
                            }

//                        Card(title: "Ratings")
//                            .content {
//                                VStack(alignment: .leading, spacing: 10) {
//
//                                    if let communityRating = viewModel.item.communityRating {
//                                        HStack {
//                                            Image(systemName: "star.fill")
//                                                .foregroundColor(.yellow)
//
//                                            Text(String(format: "%.2f", communityRating))
//                                        }
//                                    }
//                                }
//                            }
//                            .onSelect {
//                                router.route(to: \.remoteImages)
//                            }
                    }
                    .padding(.horizontal)
                    .if(UIDevice.isIPad) { view in
                        view.padding(.horizontal)
                    }
                }
            }
        }
    }
}

extension ItemView.AboutView {

    struct Card<Content: View>: View {

        private let content: () -> Content
        private var onSelect: () -> Void
        private let title: String

        var body: some View {
            Button {
                onSelect()
            } label: {
                ZStack {

                    Color.secondarySystemFill
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Spacer()

                        content()
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
                .frame(width: 330, height: 195)
            }
            .buttonStyle(.plain)
        }
    }
}

extension ItemView.AboutView.Card where Content == EmptyView {

    init(title: String) {
        self.init(
            content: { EmptyView() },
            onSelect: {},
            title: title
        )
    }
}

extension ItemView.AboutView.Card {

    func content<C: View>(@ViewBuilder _ content: @escaping () -> C) -> ItemView.AboutView.Card<C> {
        .init(
            content: content,
            onSelect: onSelect,
            title: title
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
