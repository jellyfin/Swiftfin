//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: can look busy with 3 programs, probably just do 2?

extension ChannelLibraryView {

    struct NarrowChannelView: View {

        @Environment(\.colorScheme)
        private var colorScheme

        let channel: BaseItemDto

        var body: some View {
            VStack(alignment: .leading) {
                ZStack {
                    Color.secondarySystemFill
                        .opacity(colorScheme == .dark ? 0.5 : 1)
                        .posterShadow()

                    ImageView(channel.squareImageSources(maxWidth: 120))
                        .image {
                            $0.aspectRatio(contentMode: .fit)
                        }
                        .failure {
                            SystemImageContentView(systemName: channel.typeSystemImage)
                                .background(color: .clear)
                                .imageFrameRatio(width: 2, height: 2)
                        }
                        .placeholder { _ in
                            EmptyView()
                        }
                        .padding(20)
                }
                .aspectRatio(1.0, contentMode: .fill)
                .cornerRadius(ratio: 0.0375, of: \.width)
                .posterBorder(ratio: 0.0375)

                Text(channel.displayTitle)
                    .font(.footnote.weight(.regular))
                    .foregroundColor(.primary)
                    .backport
                    .lineLimit(1, reservesSpace: true)
            }
        }
    }
}
