//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct AboutView: View {

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {

                L10n.about.text
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibility(addTraits: [.isHeader])
                    .padding(.leading, 50)

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 30) {
                        PosterButton(item: viewModel.item, type: .portrait)
                            .content {
                                EmptyView()
                            }
                            .imageOverlay {
                                EmptyView()
                            }
                            .scaleItem(1.35)
                        
                        OverviewCard(item: viewModel.item)
                        
//                        if let subtitleStreams = viewModel.playButtonItem?.subtitleStreams, !subtitleStreams.isEmpty {
//                            MediaSourcesCard(title: L10n.subtitles, mediaSources: subtitleStreams)
//                        }
//
//                        if let audioStreams = viewModel.playButtonItem?.audioStreams, !audioStreams.isEmpty {
//                            MediaSourcesCard(title: L10n.audio, mediaSources: audioStreams)
//                        }
                        
                        if viewModel.item.hasRatings {
                            RatingsCard(item: viewModel.item)
                        }
                    }
                    .padding(50)
                }
            }
            .focusSection()
        }
    }
}

extension ItemView.AboutView {
    
    struct Card: View {

//        private var alertContent: () -> any View
        private var content: () -> any View
        private var onSelect: () -> Void
        private let title: String
        private let subtitle: String?

        var body: some View {
            Button {
                onSelect()
            } label: {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Spacer()
                        .frame(maxWidth: .infinity)
                    
                    content()
                        .eraseToAnyView()
                }
                .padding2()
                .frame(width: 700, height: 405)
            }
            .buttonStyle(.card)
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
