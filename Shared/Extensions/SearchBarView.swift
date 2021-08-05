/* SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 *
 * Code sourced from AppCoda.com
 */

import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    @State private var isEditing = false

    var body: some View {
        HStack(spacing: 8) {
            // TODO: Clean up the statement as previously done
            //       in commit 93a25eb9c43eddd03e09df87722c086fb6cb6da4
            //       after Swift 5.5 is released.
            #if os(iOS)
            TextField(NSLocalizedString("Search...", comment: ""), text: $text)
                .padding(8)
                .padding(.horizontal, 16)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            #else
            TextField(NSLocalizedString("Search...", comment: ""), text: $text)
                .padding(8)
                .padding(.horizontal, 16)
                .cornerRadius(8)
            #endif
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}
