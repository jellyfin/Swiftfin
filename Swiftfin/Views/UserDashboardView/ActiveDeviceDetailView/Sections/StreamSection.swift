//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveDeviceDetailView {
    struct StreamSection: View {

        let nowPlayingItem: BaseItemDto
        let transcodingInfo: TranscodingInfo?
        let playMethod: PlayMethod?

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {

                // Create and Center the PlayMethod Description
                HStack {
                    Spacer()
                    Text(playMethod?.rawValue ?? L10n.unknown)
                    Spacer()
                }

                Divider()

                // Create the Audio Codec Flow if the stream uses Audio
                if let sourceAudioCodec = nowPlayingItem.mediaStreams?.first(where: { $0.type == .audio })?.codec {
                    getMediaComparison(
                        sourceComponent: sourceAudioCodec,
                        destinationComponent: transcodingInfo?.audioCodec ?? sourceAudioCodec
                    )
                }

                // Create the Video Codec Flow if the stream uses Video
                if let sourceVideoCodec = nowPlayingItem.mediaStreams?.first(where: { $0.type == .video })?.codec {
                    getMediaComparison(
                        sourceComponent: sourceVideoCodec,
                        destinationComponent: transcodingInfo?.videoCodec ?? sourceVideoCodec
                    )
                }

                // Create the Container Flow if the stream has a Container
                if let sourceContainer = nowPlayingItem.container {
                    getMediaComparison(
                        sourceComponent: sourceContainer,
                        destinationComponent: transcodingInfo?.container ?? sourceContainer
                    )
                }
            }
        }

        // MARK: Transcoding Details

        private func getMediaComparison(sourceComponent: String, destinationComponent: String) -> some View {
            HStack {
                Text(sourceComponent.uppercased())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Image(systemName: (destinationComponent != sourceComponent) ? "shuffle" : "arrow.right")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(destinationComponent.uppercased())
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
