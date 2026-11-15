//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SearchFilterRow: View {

    @Binding
    var query: String?

    @State
    private var isPresented = false
    @State
    private var searchQuery = ""

    @ContentBuilder
    var body: some View {
        ChevronButton(L10n.search) {
            searchQuery = query ?? ""
            isPresented = true
        } content: {
            Text(query?.nilIfBlank ?? L10n.none)
                .lineLimit(1)
        }
        .alert(L10n.search, isPresented: $isPresented) {
            TextField(L10n.search, text: $searchQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button(L10n.cancel, role: .cancel) {}

            Button(L10n.save) {
                query = searchQuery.nilIfBlank
            }
        }
    }
}
