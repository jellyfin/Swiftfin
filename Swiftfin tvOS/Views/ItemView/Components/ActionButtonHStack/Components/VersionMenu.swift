//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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

        // MARK: - Body

        var body: some View {
            ActionMenu(L10n.trailers, icon: "list.dash") {
                // TODO: Replace with Picker
                ForEach(mediaSources, id: \.hashValue) { mediaSource in
                    Button {
                        viewModel.send(.selectMediaSource(mediaSource))
                    } label: {
                        if let selectedMediaSource = viewModel.selectedMediaSource, selectedMediaSource == mediaSource {
                            Label(selectedMediaSource.displayTitle, systemImage: "checkmark")
                        } else {
                            Text(mediaSource.displayTitle)
                        }
                    }
                }
            }
        }
    }
}
