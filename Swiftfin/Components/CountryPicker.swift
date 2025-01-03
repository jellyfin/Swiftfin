//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CountryPicker: View {
    let title: String
    @Binding
    var selectedCountryCode: String?

    // MARK: - Get all localized countries

    private var countries: [(code: String?, name: String)] {
        var uniqueCountries = Set<String>()

        var countryList: [(code: String?, name: String)] = Locale.isoRegionCodes.compactMap { code in
            let locale = Locale.current
            if let name = locale.localizedString(forRegionCode: code),
               !uniqueCountries.contains(code)
            {
                uniqueCountries.insert(code)
                return (code, name)
            }
            return nil
        }
        .sorted { $0.name < $1.name }

        // Add None as an option at the top of the list
        countryList.insert((code: nil, name: L10n.none), at: 0)
        return countryList
    }

    // MARK: - Body

    var body: some View {
        Picker(title, selection: $selectedCountryCode) {
            ForEach(countries, id: \.code) { country in
                Text(country.name).tag(country.code)
            }
        }
    }
}
