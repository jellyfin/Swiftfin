//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct AttributesHStack: View {

        @ObservedObject
        var viewModel: ItemViewModel

        var body: some View {
            HStack {
                if let officialRating = viewModel.item.officialRating {
                    AttributeOutlineView(text: officialRating)
                }

                if let selectedPlayerViewModel = viewModel.selectedVideoPlayerViewModel {
                    if selectedPlayerViewModel.item.isHD ?? false {
                        AttributeFillView(text: "HD")
                    }

                    if (selectedPlayerViewModel.videoStream.width ?? 0) > 3800 {
                        AttributeFillView(text: "4K")
                    }

                    if selectedPlayerViewModel.audioStreams.contains(where: { $0.channelLayout == "5.1" }) {
                        AttributeFillView(text: "5.1")
                    }

                    if selectedPlayerViewModel.audioStreams.contains(where: { $0.channelLayout == "7.1" }) {
                        AttributeFillView(text: "7.1")
                    }

                    if !selectedPlayerViewModel.subtitleStreams.isEmpty {
                        AttributeOutlineView(text: "CC")
                    }
                }
            }
            .foregroundColor(Color(UIColor.darkGray))
        }
    }
}
