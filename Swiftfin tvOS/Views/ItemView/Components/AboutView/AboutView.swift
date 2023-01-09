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
            VStack(alignment: .leading) {

                L10n.about.text
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.leading, 50)

                ScrollView(.horizontal) {
                    HStack(spacing: 30) {
                        ImageView(
                            viewModel.item.type == .episode ? viewModel.item.seriesImageSource(.primary, maxWidth: 300) : viewModel.item
                                .imageSource(.primary, maxWidth: 300)
                        )
                        .failure {
                            InitialFailureView(viewModel.item.title.initials)
                        }
                        .posterStyle(type: .portrait, width: 270)

                        InformationCard(
                            title: viewModel.item.displayTitle,
                            content: viewModel.item.overview ?? L10n.noOverviewAvailable
                        )

                        if let subtitleStreams = viewModel.playButtonItem?.subtitleStreams, !subtitleStreams.isEmpty {
                            InformationCard(
                                title: L10n.subtitles,
                                content: subtitleStreams.compactMap(\.displayTitle).joined(separator: ", ")
                            )
                        }

                        if let audioStreams = viewModel.playButtonItem?.audioStreams, !audioStreams.isEmpty {
                            InformationCard(title: L10n.audio, content: audioStreams.compactMap(\.displayTitle).joined(separator: ", "))
                        }
                    }
                    .padding(.horizontal, 50)
                    .padding(.top)
                    .padding(.bottom, 100)
                }
            }
            .focusSection()
        }
    }
}
