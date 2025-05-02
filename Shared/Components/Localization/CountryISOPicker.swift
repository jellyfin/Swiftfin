//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CountryISOPicker: View {

    // MARK: - State Object

    @StateObject
    private var viewModel = CountryViewModel()

    // MARK: - Picker Title

    private let title: String

    // MARK: - ISO Language Codes

    @Binding
    private var twoLetterISORegion: String?
    @Binding
    private var threeLetterISORegion: String?

    // MARK: - Selected Culture

    @Binding
    private var selectedCountry: CountryInfo?

    // MARK: - Body

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial, .refreshing:
                ProgressView()
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            }
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        if viewModel.countries.isEmpty {
            Text(L10n.none)
                .foregroundStyle(.secondary)
        } else {

            let countries = availableCountries

            /// Create a binding to the index in the array
            let indexBinding = Binding<Int>(
                get: {
                    /// Primary - Try to find by selected country
                    if let selectedCountry = selectedCountry {
                        for (index, country) in countries.enumerated() {
                            if getThreeLetterCode(from: country) == getThreeLetterCode(from: selectedCountry) &&
                                getTwoLetterCode(from: country) == getTwoLetterCode(from: selectedCountry)
                            {
                                return index
                            }
                        }
                    }

                    /// Secondary - Try by 2 letter country code
                    if let countryCode = twoLetterISORegion {
                        for (index, country) in countries.enumerated() {
                            if let code = getTwoLetterCode(from: country),
                               code == countryCode
                            {
                                return index
                            }
                        }
                    }

                    /// Tertiary - Try by 3 letter country code
                    if let countryCode = threeLetterISORegion {
                        for (index, country) in countries.enumerated() {
                            if let code = getThreeLetterCode(from: country),
                               code == countryCode
                            {
                                return index
                            }
                        }
                    }
                    return 0
                },
                set: { newIndex in
                    if newIndex >= 0 && newIndex < countries.count {
                        let country = countries[newIndex]
                        twoLetterISORegion = getTwoLetterCode(from: country)
                        threeLetterISORegion = getThreeLetterCode(from: country)
                        selectedCountry = country
                    }
                }
            )

            isoPicker(title, selection: indexBinding)
        }
    }

    // MARK: - Picker by Platform

    @ViewBuilder
    private func isoPicker(_ title: String, selection: Binding<Int>) -> some View {
        #if os(tvOS)
        ListRowMenu(title, subtitle: {
            Text(getDisplayName(for: availableCountries[selection.wrappedValue]))
        }) {
            ForEach(availableCountries.indices, id: \.self) { index in
                let country = availableCountries[index]
                Button(getDisplayName(for: country)) {
                    selection.wrappedValue = index
                }
            }
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(.zero)
        #else
        Picker(title, selection: selection) {
            ForEach(0 ..< availableCountries.count, id: \.self) { index in
                Text(getDisplayName(for: availableCountries[index]))
                    .tag(index)
            }
        }
        #endif
    }

    // MARK: - Get Available Localizations

    private var availableCountries: [CountryInfo] {
        let jellyfinCountries = viewModel.countries
        let existingTwoLetterCodes = Set(jellyfinCountries.compactMap(\.twoLetterISORegionName))

        let systemCountriesDict = Locale.isoRegionCodes.reduce(into: [String: CountryInfo]()) { dict, code in
            guard !dict.keys.contains(code),
                  !existingTwoLetterCodes.contains(code),
                  let displayName = Locale.current.localizedString(forRegionCode: code)
            else { return }

            dict[code] = CountryInfo(
                displayName: displayName,
                name: code,
                threeLetterISORegionName: nil,
                twoLetterISORegionName: code
            )
        }

        return [emptyCountryInfo] + (jellyfinCountries + Array(systemCountriesDict.values))
            .sorted { getDisplayName(for: $0) < getDisplayName(for: $1) }
    }

    // MARK: - Get 2 Letter ISO with Fallbacks

    private func getTwoLetterCode(from country: CountryInfo) -> String? {
        country.twoLetterISORegionName
    }

    // MARK: - Get 3 Letter ISO with Fallbacks

    private func getThreeLetterCode(from country: CountryInfo) -> String? {
        country.threeLetterISORegionName
    }

    // MARK: - Get DisplayName with Fallbacks

    private func getDisplayName(for country: CountryInfo) -> String {
        country.displayName ?? country.name ?? L10n.unknown
    }

    // MARK: - Get 3 Letter ISO with Fallbacks

    private var emptyCountryInfo: CountryInfo {
        .init(
            displayName: L10n.none,
            name: L10n.none,
            threeLetterISORegionName: nil,
            twoLetterISORegionName: nil
        )
    }
}

extension CountryISOPicker {

    // MARK: - Initialize with CultureDto

    init(_ title: String, selectedCountry: Binding<CountryInfo?>) {
        self.title = title
        self._twoLetterISORegion = .constant(selectedCountry.wrappedValue?.twoLetterISORegionName)
        self._threeLetterISORegion = .constant(selectedCountry.wrappedValue?.threeLetterISORegionName)
        self._selectedCountry = selectedCountry
    }

    // MARK: - Initialize with 2 letter ISO code

    init(_ title: String, twoLetterISORegion: Binding<String?>) {
        self.title = title
        self._twoLetterISORegion = twoLetterISORegion
        self._threeLetterISORegion = .constant(nil)
        self._selectedCountry = .constant(nil)
    }

    // MARK: - Initialize with 3 letter ISO code

    init(_ title: String, threeLetterISORegion: Binding<String?>) {
        self.title = title
        self._twoLetterISORegion = .constant(nil)
        self._threeLetterISORegion = threeLetterISORegion
        self._selectedCountry = .constant(nil)
    }
}
