//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ServerTasksView {

    struct DestructiveServerTask: View {

        @State
        private var isPresented: Bool = false

        let title: String
        let systemName: String
        let message: String
        let action: () -> Void

        // MARK: - Body

        var body: some View {
            Button(role: .destructive) {
                isPresented = true
            } label: {
                HStack {
                    Text(title)
                        .fontWeight(.semibold)

                    Spacer()

                    Image(systemName: systemName)
                        .backport
                        .fontWeight(.bold)
                }
            }
            .confirmationDialog(
                title,
                isPresented: $isPresented,
                titleVisibility: .visible
            ) {
                Button(title, role: .destructive, action: action)
            } message: {
                Text(message)
            }
        }
    }
}
