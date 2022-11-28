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
                
                if viewModel.item.isHD ?? false {
                    AttributeFillView(text: "HD")
                }
                
                if let selectedMediaSource = viewModel.selectedMediaSource {
                    if let videoStream = selectedMediaSource.mediaStreams?.first(where: { $0.type == .video }),
                       (videoStream.width ?? 0) > 3800 {
                        AttributeFillView(text: "4K")
                    }
                    
                    if let audioStreams = selectedMediaSource.mediaStreams?.filter({ $0.type == .audio }) {
                        if audioStreams.contains(where: { $0.channelLayout == "5.1" }) {
                            AttributeFillView(text: "5.1")
                        }
                        
                        if audioStreams.contains(where: { $0.channelLayout == "7.1" }) {
                            AttributeFillView(text: "7.1")
                        }
                    }
                    
                    if let _ = selectedMediaSource.mediaStreams?.filter({ $0.type == .subtitle }) {
                        AttributeOutlineView(text: "CC")
                    }
                }
            }
            .foregroundColor(Color(UIColor.darkGray))
        }
    }
}
