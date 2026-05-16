//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Engine
import JellyfinAPI
import SwiftUI

extension EditMetadataView {

    struct EpisodeSection: View {

        @Binding
        var item: BaseItemDto

        // MARK: - Body

        var body: some View {
            Section(L10n.season) {

                // MARK: - Season Number

                StateAdapter(initialValue: false) { isPresented in
                    ChevronButton(
                        L10n.season,
                        content: item.parentIndexNumber?.description ?? ""
                    ) {
                        isPresented.wrappedValue = true
                    }
                    .alert(L10n.season, isPresented: isPresented) {
                        TextField(
                            L10n.season,
                            value: $item.parentIndexNumber,
                            format: .number
                        )
                        .keyboardType(.numberPad)
                    } message: {
                        Text(L10n.enterSeasonNumber)
                    }
                }

                // MARK: - Episode Number

                StateAdapter(initialValue: false) { isPresented in
                    ChevronButton(
                        L10n.episode,
                        content: item.indexNumber?.description ?? ""
                    ) {
                        isPresented.wrappedValue = true
                    }
                    .alert(L10n.episode, isPresented: isPresented) {
                        TextField(
                            L10n.episode,
                            value: $item.indexNumber,
                            format: .number
                        )
                        .keyboardType(.numberPad)
                    } message: {
                        Text(L10n.enterEpisodeNumber)
                    }
                }
            }
        }
    }
}
