//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct PlayNextItem: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var nextItem: MediaPlayerItemProvider? = nil

        @ViewBuilder
        private func content<Q: MediaPlayerQueue>(_ queue: Q) -> some View {
            WithObservedObject(queue) { queue in
                Button(
                    L10n.playNextItem,
                    systemImage: "forward.end.circle.fill"
                ) {
                    guard let nextItem else { return }
                    manager.send(.playNewItem(provider: nextItem))
                }
                .disabled(nextItem == nil)
                .onAppear {
                    self.nextItem = queue.nextItem
                }
                .onChange(of: queue.nextItem) { newValue in
                    self.nextItem = newValue
                }
            }
        }

        var body: some View {
            if let queue = manager.queue {
                content(queue)
                    .eraseToAnyView()
            }
        }
    }
}
