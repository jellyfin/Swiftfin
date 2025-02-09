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

    struct SelectVersionButton: View {

        @ObservedObject
        var viewModel: ItemViewModel

        // MARK: - Body

        var body: some View {
            Menu {
                if let playButtonItem = viewModel.playButtonItem,
                   let mediaSources = playButtonItem.mediaSources,
                   mediaSources.count > 1
                {
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
            } label: {
                HStack {
                    Text(L10n.version)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "list.dash")
                        .foregroundStyle(.secondary)
                        .backport
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.primary, .secondary)
        }
    }
}
