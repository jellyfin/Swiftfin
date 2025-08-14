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

    // TODO: take in binding instead of view model
    struct VersionMenu: View {

        @ObservedObject
        var viewModel: ItemViewModel

        let mediaSources: [MediaSourceInfo]

        private var selectedMediaSourceBinding: Binding<MediaSourceInfo?> {
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
                Picker(L10n.version, selection: selectedMediaSourceBinding) {
                    ForEach(mediaSources, id: \.hashValue) { mediaSource in
                        Button {
                            Text(mediaSource.displayTitle)
                        }
                        .tag(mediaSource as MediaSourceInfo?)
                    }
                }
            }
        }
    }
}
