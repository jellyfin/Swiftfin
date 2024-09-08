//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ActiveSessionRowView: View {
    @Default(.appAppearance)
    private var appAppearance

    let session: SessionInfo
    let onSelect: () -> Void?

    var body: some View {
        Button {
            onSelect()
        } label: {
            ZStack(alignment: .topLeading) {
                if let nowPlayingItem = session.nowPlayingItem {
                    ImageView(nowPlayingItem.cinematicImageSources(maxWidth: 500).first!)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 4
                            )
                        )
                        .scaledToFill()
                        .overlay(
                            Color.black.opacity(0.7)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 4
                                    )
                                )
                        )
                        .clipped()
                }

                VStack(alignment: .leading) {
                    HStack {
                        UserSection(session: session)
                            .foregroundColor(.primary)
                        if session.nowPlayingItem == nil {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    if session.nowPlayingItem != nil {
                        Spacer()
                        ContentSection(session: session)
                        Spacer()
                        ProgressSection(session: session)
                            .font(.caption)
                    }
                }
                .shadow(radius: 10)
                .padding(session.nowPlayingItem != nil ? 16 : 0)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
