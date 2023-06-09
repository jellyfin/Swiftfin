//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct MediaSourceInfoView: View {

        let item: BaseItemDto
        let source: MediaSourceInfo

        @ViewBuilder
        private func streamList(title: String, streams: [MediaStream]?) -> some View {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3)
                    .frame(maxWidth: .infinity)

                ForEach.let(streams, id: \.index) { stream in
                    Text(stream.displayTitle ?? .emptyDash)
                }
            }
        }

        var body: some View {
            GeometryReader { proxy in
                VStack(alignment: .center) {
                    Text(item.displayTitle)
                        .font(.title)
                        .frame(maxHeight: proxy.size.height * 0.33)

                    HStack {

                        streamList(title: L10n.video, streams: source.videoStreams)
                            .frame(maxWidth: .infinity)

                        streamList(title: L10n.audio, streams: source.audioStreams)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(alignment: .top)
                    .padding2(.horizontal)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct Test_Preview: PreviewProvider {

    static var previews: some View {
        ItemView.MediaSourceInfoView(
            item: .init(name: "Top Gun"),
            source: .init(mediaStreams: [.init(displayTitle: "Test", type: .video)])
        )
    }
}
