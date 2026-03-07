//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import SwiftUI

extension ConnectToServerView {

    struct LocalServerButton: View {

        let server: ServerState
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(server.name)
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text(server.currentURL.absoluteString)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.body)
                        .fontWeight(.regular)
                        .foregroundStyle(.secondary)
                }
                #if os(tvOS)
                .padding()
                #endif
            }
            .foregroundStyle(.primary, .secondary)
            .buttonStyle(.card)
        }
    }
}
