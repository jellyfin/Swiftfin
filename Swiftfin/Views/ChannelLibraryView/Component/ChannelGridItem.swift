//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ChannelsView {

    struct ChannelGridItem: View {

        let channel: ChannelProgram

//        private var programLabel: some View {
//            HStack(alignment: .top) {
//                Text()
//
//                Text(titleText)
//            }
//            .font(.footnote)
//            .lineLimit(2)
//        }

        var body: some View {

            Button {} label: {
                VStack(alignment: .leading) {
                    ImageView(channel.portraitPosterImageSource(maxWidth: 130))
                        .overlay {
                            if let progress = channel.currentProgram?.programProgress {
                                ProgressBar(progress: progress)
                            }
                        }
                        .aspectRatio(1.0, contentMode: .fit)

                    Text(channel.displayTitle)
                        .font(.body)
                        .lineLimit(1)
                        .foregroundColor(Color.jellyfinPurple)
                        .frame(alignment: .leading)
                }
                .frame(height: 130)
            }
            .background {
                Color.red
                    .opacity(0.5)
            }
        }
    }
}
