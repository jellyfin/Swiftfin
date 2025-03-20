//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveSessionDetailView {

    struct TranscodeSection: View {

        let transcodeReasons: [TranscodeReason]

        // MARK: - Body

        var body: some View {
            VStack(alignment: .center) {

                let transcodeIcons = Set(transcodeReasons.map(\.systemImage)).sorted()

                HStack {
                    ForEach(transcodeIcons, id: \.self) { icon in
                        Image(systemName: icon)
                            .foregroundStyle(.primary)
                    }
                }

                Divider()

                ForEach(transcodeReasons, id: \.self) { reason in
                    Text(reason)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
    }
}
