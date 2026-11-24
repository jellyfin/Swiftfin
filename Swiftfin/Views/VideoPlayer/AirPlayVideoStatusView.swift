//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
import SwiftUI

/// Shown in place of the video while it plays on an AirPlay receiver or is being prepared for one.
struct AirPlayVideoStatusView: View {

    private let controller = AirPlayVideoController.shared

    @ContentBuilder
    var body: some View {
        let status = controller.phase
        if status.isTransitioning || (status == .active && controller.isExternalVideoActive) {
            VStack(spacing: 16) {
                Image(systemName: "airplayvideo")
                    .font(.system(size: 56))

                Text(status.displayTitle)
                    .font(.title2)

                if status.isTransitioning {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .foregroundStyle(.white)
            .tint(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        }
    }
}
#endif
