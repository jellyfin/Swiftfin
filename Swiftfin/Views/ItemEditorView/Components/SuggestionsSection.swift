//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemEditorView {

    struct SuggestionsSection: View {

        @Binding
        var name: String

        let suggestions: [String]

        // MARK: - Body

        var body: some View {
            if name.isNotEmpty && suggestions.isNotEmpty {
                Section(L10n.suggestions) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        suggestionButton(suggestion)
                    }
                }
            }
        }

        // MARK: - Button

        private func suggestionButton(_ item: String) -> some View {
            Button(item) {
                name = item
            }
            .foregroundStyle(.primary)
            .disabled(name == item)
        }
    }
}
