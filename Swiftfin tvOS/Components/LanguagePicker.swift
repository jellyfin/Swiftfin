//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LanguagePicker: View {
    let title: String
    @Binding
    var selectedLanguageCode: String?

    // MARK: - Get all localized languages

    private var languages: [(code: String?, name: String)] {
        var uniqueLanguages = Set<String>()

        var languageList: [(code: String?, name: String)] = Locale.availableIdentifiers.compactMap { identifier in
            let locale = Locale(identifier: identifier)
            if let code = locale.language.languageCode?.identifier,
               let name = locale.localizedString(forLanguageCode: code),
               !uniqueLanguages.contains(code)
            {
                uniqueLanguages.insert(code)
                return (code, name)
            }
            return nil
        }
        .sorted { $0.name < $1.name }

        // Add None as an option at the top of the list
        languageList.insert((code: nil, name: L10n.none), at: 0)
        return languageList
    }

    // MARK: - Body

    var body: some View {
        ListRowMenu(title, subtitle: {
            Text(languages.first { $0.code == selectedLanguageCode }?.name ?? L10n.none)
        }) {
            ForEach(languages, id: \.code) { language in
                Button(language.name) {
                    selectedLanguageCode = language.code
                }
            }
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(.zero)
    }
}
