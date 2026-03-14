//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ProgramsView {

    struct ProgramButtonContent: View {

        let program: BaseItemDto

        var body: some View {
            VStack(alignment: .leading) {

                Text(program.channelName ?? .emptyDash)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1, reservesSpace: true)

                Text(program.displayTitle)
                    .font(.footnote.weight(.regular))
                    .foregroundColor(.primary)
                    .lineLimit(1, reservesSpace: true)

                HStack(spacing: 2) {
                    if let startDate = program.startDate {
                        Text(startDate, style: .time)
                    } else {
                        Text(String.emptyDash)
                    }

                    Text("-")

                    if let endDate = program.endDate {
                        Text(endDate, style: .time)
                    } else {
                        Text(String.emptyDash)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }
}
