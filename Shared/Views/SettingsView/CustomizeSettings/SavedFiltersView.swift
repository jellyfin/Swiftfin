//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SavedFiltersView: View {

    @Router
    private var router

    @StoredValue(.User.savedFilters)
    private var savedFilters

    var body: some View {
        Form(systemImage: "line.3.horizontal.decrease") {
            if savedFilters.isEmpty {
                Text(L10n.none)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(savedFilters) { filter in
                    ChevronButton(filter.name) {
                        router.route(to: .editFilters(filters: filter.filters, savedFilter: filter))
                    }
                }
            }
        }
        .navigationTitle(L10n.savedFilters)
    }
}
