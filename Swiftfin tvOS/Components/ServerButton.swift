//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ServerButton: View {

    let server: SwiftfinStore.State.Server
    private var onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                Image(systemName: "server.rack")
                    .font(.system(size: 72))
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 5) {
                    Text(server.name)
                        .font(.title2)
                        .foregroundColor(.primary)

                    Text(server.currentURL.absoluteString)
                        .font(.footnote)
                        .disabled(true)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(10)
        }
        .buttonStyle(.card)
    }
}

extension ServerButton {

    init(server: SwiftfinStore.State.Server) {
        self.server = server
        self.onSelect = {}
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
