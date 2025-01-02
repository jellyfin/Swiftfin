//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ChannelLibraryView {

    struct CompactChannelView: View {

        @Environment(\.colorScheme)
        private var colorScheme

        let channel: BaseItemDto

        private var onSelect: () -> Void

        var body: some View {
            Button {
                onSelect()
            } label: {
                VStack(alignment: .leading) {
                    ZStack {
                        Color.secondarySystemFill
                            .opacity(colorScheme == .dark ? 0.5 : 1)
                            .posterShadow()

                        ImageView(channel.imageSource(.primary, maxWidth: 120))
                            .image {
                                $0.aspectRatio(contentMode: .fit)
                            }
                            .failure {
                                SystemImageContentView(systemName: channel.systemImage, ratio: 0.5)
                                    .background(color: .clear)
                            }
                            .placeholder { _ in
                                EmptyView()
                            }
                            .padding(5)
                    }
                    .aspectRatio(1.0, contentMode: .fill)
                    .cornerRadius(ratio: 0.0375, of: \.width)
                    .posterBorder(ratio: 0.0375, of: \.width)

                    Text(channel.displayTitle)
                        .font(.footnote.weight(.regular))
                        .foregroundColor(.primary)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                        .font(.footnote.weight(.regular))
                }
            }
            .buttonStyle(.plain)
        }
    }
}

extension ChannelLibraryView.CompactChannelView {

    init(channel: BaseItemDto) {
        self.init(
            channel: channel,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
