//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension SeriesEpisodeSelector {

    struct EpisodeContent: View {

        @Default(.accentColor)
        private var accentColor

        private var onSelect: () -> Void

        let subHeader: String
        let header: String
        let content: String

        @ViewBuilder
        private var subHeaderView: some View {
            Text(subHeader)
                .font(.footnote)
                .foregroundColor(.secondary)
        }

        @ViewBuilder
        private var headerView: some View {
            Text(header)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.bottom, 1)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }

        @ViewBuilder
        private var contentView: some View {
            // TODO: clean up when TruncatedText works properly
            //       with `reservesSpace`
            ZStack(alignment: .topLeading) {
                Color.clear

                Text("fixme")
                    .hidden()
                    .backport
                    .lineLimit(3, reservesSpace: true)

                TruncatedText(content)
                    .lineLimit(3)
            }
            .font(.caption.weight(.light))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.leading)
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                VStack(alignment: .leading) {
                    subHeaderView

                    headerView

                    contentView
                }
            }
        }
    }
}

extension SeriesEpisodeSelector.EpisodeContent {

    init(
        subHeader: String,
        header: String,
        content: String
    ) {
        self.subHeader = subHeader
        self.header = header
        self.content = content
        self.onSelect = {}
    }

    func onSelect(perform action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
