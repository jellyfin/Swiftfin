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

        @ObservedObject
        var viewModel: ItemViewModel

        let mediaSources: [MediaSourceInfo]

        private var selectedAudioStreamIndex: Binding<Int?> {
            Binding(
                get: { viewModel.selectedMediaSource?.defaultAudioStreamIndex },
                set: { newIndex in
                    guard var selectedMediaSource = viewModel.selectedMediaSource else { return }
                    selectedMediaSource.defaultAudioStreamIndex = newIndex
                    viewModel.send(.selectMediaSource(selectedMediaSource))
                }
            )
        }

        private var selectedSubtitleStreamIndex: Binding<Int?> {
            Binding(
                get: { viewModel.selectedMediaSource?.defaultSubtitleStreamIndex },
                set: { newIndex in
                    guard var selectedMediaSource = viewModel.selectedMediaSource else { return }
                    selectedMediaSource.defaultSubtitleStreamIndex = newIndex
                    viewModel.send(.selectMediaSource(selectedMediaSource))
                }
            )
        }

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
                Picker(L10n.version, selection: selectedMediaSource) {
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
