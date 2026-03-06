//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

/// A non-interactive pill overlay that displays a server-pushed message.
///
/// This view uses a plain SwiftUI overlay (not a UIKit presentation) so that
/// it never interrupts video playback when shown over the video player.
/// It is intended to be placed at `.bottomLeading` alignment.
struct ServerMessageOverlayView: View {

    @InjectedObject(\.mainServerMessageProxy)
    private var proxy

    var body: some View {
        if proxy.isPresenting, !proxy.body.isEmpty {
            Text(proxy.body)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .allowsHitTesting(false)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}
