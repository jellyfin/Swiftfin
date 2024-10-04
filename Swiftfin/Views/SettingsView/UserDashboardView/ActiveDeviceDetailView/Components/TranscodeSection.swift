//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveDeviceDetailView {

    struct TranscodeSection: View {

        let transcodeReasons: [TranscodeReason]

        // MARK: - Body

        var body: some View {
            if !transcodeReasons.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    getActiveTranscodeIcons(reasons: transcodeReasons)

                    Divider()

                    getActiveTranscodeReasons(reasons: transcodeReasons)
                }
            }
        }

        // MARK: - Get Active Transcode Icon

        @ViewBuilder
        private func getActiveTranscodeIcons(reasons: [TranscodeReason]) -> some View {

            let transcodeIcons = Set(reasons.map(\.systemImage)).sorted()

            HStack {
                Spacer()
                ForEach(transcodeIcons, id: \.self) { icon in
                    Image(systemName: icon)
                        .foregroundColor(.primary)
                }
                Spacer()
            }
        }

        // MARK: - Get Active Transcode Reason Descriptions

        @ViewBuilder
        private func getActiveTranscodeReasons(reasons: [TranscodeReason]) -> some View {
            VStack(alignment: .center, spacing: 8) {
                ForEach(reasons, id: \.self) { reason in
                    Text(reason.description)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
    }
}
