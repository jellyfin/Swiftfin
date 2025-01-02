//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import SwiftUI

extension ConnectToServerView {

    struct LocalServerButton: View {

        // MARK: - Environment Variables

        @Environment(\.isEnabled)
        private var isEnabled: Bool

        // MARK: - Local Server Variables

        private let server: ServerState
        private let action: () -> Void

        // MARK: - Initializer

        init(server: ServerState, action: @escaping () -> Void) {
            self.server = server
            self.action = action
        }

        // MARK: - Local Server Button

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
                        .font(.body.weight(.regular))
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .disabled(!isEnabled)
            .buttonStyle(.card)
            .foregroundStyle(.primary)
        }
    }
}
