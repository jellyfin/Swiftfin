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

    let title: String

    // MARK: - ISO Language Code

    @Binding
    var threeLetterISORegionName: String?

    // MARK: - Selected Culture

    @Binding
    var selectedCountry: CountryInfo?

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
            /// Convert to array for indexed access
            let countriesArray = [emptyCountryInfo] + Array(viewModel.countries)
                .sorted { getDisplayName(for: $0) < getDisplayName(for: $1) }

            /// Create a binding to the INDEX in the array
            let indexBinding = Binding<Int>(
                get: {
                    /// Primarily - Try to find by selected country
                    if let selectedCountry = selectedCountry {
                        for (index, country) in countriesArray.enumerated() {
                            if getThreeLetterCode(from: country) == getThreeLetterCode(from: selectedCountry) {
                                return index
                            }
                        }
                    }

                    /// Secondary - Try by country code
                    if let countryCode = threeLetterISORegionName {
                        for (index, country) in countriesArray.enumerated() {
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
                    if newIndex >= 0 && newIndex < countriesArray.count {
                        let country = countriesArray[newIndex]
                        threeLetterISORegionName = getThreeLetterCode(from: country)
                        selectedCountry = country
                    }
                }
            )

            Picker(title, selection: indexBinding) {
                ForEach(0 ..< countriesArray.count, id: \.self) { index in
                    let country = countriesArray[index]
                    Text(getDisplayName(for: country))
                        .tag(index)
                }
            }
        }
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

    // MARK: - Initialize with three letter ISO code

    init(_ title: String, threeLetterISORegionName: Binding<String?>) {
        self.title = title
        self._threeLetterISORegionName = threeLetterISORegionName
        self._selectedCountry = .constant(nil)
    }

    // MARK: - Initialize with CultureDto

    init(_ title: String, selectedCountry: Binding<CountryInfo?>) {
        self.title = title
        self._selectedCountry = selectedCountry
        self._threeLetterISORegionName = .constant(selectedCountry.wrappedValue?.threeLetterISORegionName)
    }
}
