//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
                .lineLimit(1)
        }

        @ViewBuilder
        private var headerView: some View {
            Text(header)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(1)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 1)
        }

        @ViewBuilder
        private var contentView: some View {
            Text(content)
                .font(.caption.weight(.light))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .backport
                .lineLimit(3, reservesSpace: true)
                .font(.caption.weight(.light))
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                VStack(alignment: .leading) {
                    subHeaderView

                    headerView

                    contentView
                        .iOS15 { v in
                            v.frame(
                                height: "A\nA\nA".height(
                                    withConstrainedWidth: 10,
                                    font: Font.caption.uiFont ?? UIFont.preferredFont(forTextStyle: .body)
                                )
                            )
                        }

                    L10n.seeMore.text
                        .font(.caption.weight(.light))
                        .foregroundStyle(accentColor)
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
