//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay {
    
    struct OverlayButtonStyle: ButtonStyle {
        
        let onPressed: (Bool) -> Void
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .labelStyle(.iconOnly)
                .contentShape(Rectangle())
                .padding(8)
                .scaleEffect(
                    configuration.isPressed ? 0.8 : 1,
                    anchor: .init(x: 0.5, y: 0.5)
                )
                .animation(.bouncy(duration: 0.25, extraBounce: 0.25), value: configuration.isPressed)
                .onChange(of: configuration.isPressed, perform: onPressed)
        }
    }
}
