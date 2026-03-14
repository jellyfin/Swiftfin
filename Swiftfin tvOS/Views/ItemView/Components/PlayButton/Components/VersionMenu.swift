//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct VersionMenu: View {

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        @ObservedObject
        var viewModel: ItemViewModel

        let mediaSources: [MediaSourceInfo]

        // MARK: - Selected Media Source Binding

        private var selectedMediaSource: Binding<MediaSourceInfo?> {
            Binding(
                get: { viewModel.selectedMediaSource },
                set: { newSource in
                    if let newSource {
                        viewModel.send(.selectMediaSource(newSource))
                    }
                }
            )
        }

        // MARK: - Body

        var body: some View {
            Menu(L10n.version, systemImage: "list.dash") {
                Picker(L10n.version, selection: selectedMediaSource) {
                    ForEach(mediaSources, id: \.hashValue) { mediaSource in
                        Text(mediaSource.displayTitle)
                            .tag(mediaSource as MediaSourceInfo?)
                    }
                }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.material)
        }
    }
}
