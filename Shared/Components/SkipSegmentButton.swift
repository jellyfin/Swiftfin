//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

struct SkipSegmentButton: View {

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    var body: some View {
        if let segment = manager.currentSegment, let type = segment.type {
            Button(action: {
                manager.skipCurrentSegment()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "forward.end.fill")
                    Text("Skip \(type.rawValue)")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .transition(.opacity)
            .animation(.spring(), value: manager.currentSegment)
        }
    }
}
