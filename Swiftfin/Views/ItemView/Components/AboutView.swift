//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ItemView {

    struct AboutView: View {

        @Default(.accentColor)
        private var accentColor

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
                                if let overview = viewModel.item.overview {
                                    TruncatedTextView(text: overview)
                                        .lineLimit(4)
                                        .font(.footnote)
                                        .seeMoreAction {
                                            router.route(to: \.itemOverview, viewModel.item)
                                        }
                                        .foregroundColor(.secondary)
                                } else {
                                    L10n.noOverviewAvailable.text
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .onSelect {
                                router.route(to: \.itemOverview, viewModel.item)
                            }

                        if viewModel.item.type == .episode ||
                            viewModel.item.type == .movie,
                            let mediaSources = viewModel.item.mediaSources
                        {
                            ForEach(mediaSources) { source in
                                Card(title: L10n.media, subtitle: mediaSources.count > 1 ? source.displayTitle : nil)
                                    .content {
                                        if let mediaStreams = source.mediaStreams {
                                            VStack(alignment: .leading) {
                                                ForEach(mediaStreams.prefix(4), id: \.index) { mediaStream in
                                                    Text(mediaStream.displayTitle ?? .emptyDash)
                                                        .lineLimit(1)
                                                        .font(.footnote)
                                                        .foregroundColor(.secondary)
                                                }

                                                if mediaStreams.count > 4 {
                                                    L10n.seeMore.text
                                                        .font(.footnote)
                                                        .foregroundColor(accentColor)
                                                }
                                            }
                                        }
                                    }
                                    .onSelect {
                                        router.route(to: \.mediaSourceInfo, source)
                                    }
                            }
                        }
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

    struct Card: View {

        private var content: () -> any View
        private var onSelect: () -> Void
        private let title: String
        private let subtitle: String?

        var body: some View {
            Button {
                onSelect()
            } label: {
                ZStack(alignment: .leading) {

                    Color.secondarySystemFill
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .lineLimit(2)

                        if let subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                        }

                        Spacer()

                        content()
                            .eraseToAnyView()
                    }
                    .padding()
                }
                .frame(width: 330, height: 195)
            }
            .buttonStyle(.plain)
        }
    }
}

extension ItemView.AboutView.Card {

    init(title: String, subtitle: String? = nil) {
        self.init(
            content: { EmptyView() },
            onSelect: {},
            title: title,
            subtitle: subtitle
        )
    }

    func content(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.content, with: content)
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
