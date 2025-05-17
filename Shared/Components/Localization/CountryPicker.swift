//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct CountryPicker: View {

    // MARK: - State Object

    @StateObject
    private var viewModel = CountryViewModel()

    // MARK: - Selection State

    @State
    private var selectedIndex: Int = 0

    // MARK: - Countries List

    private var countries: [CountryInfo] {
        [emptyCountryInfo] + Array(viewModel.countries)
            .sorted { getDisplayName(for: $0) < getDisplayName(for: $1) }
    }

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
        .onChange(of: viewModel.countries) { _ in
            updateSelectedIndex()
        }
        .onChange(of: selectedCountry) { _ in
            updateSelectedIndex()
        }
        .onChange(of: twoLetterISORegion) { _ in
            updateSelectedIndex()
        }
        .onChange(of: threeLetterISORegion) { _ in
            updateSelectedIndex()
        }
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        if countries.isEmpty {
            Text(L10n.none)
                .foregroundStyle(.secondary)
        } else {
            isoPicker(title, countries: countries, selection: $selectedIndex)
                .onChange(of: selectedIndex) { newIndex in
                    if newIndex >= 0 && newIndex < countries.count {
                        let country = countries[newIndex]
                        twoLetterISORegion = getTwoLetterCode(from: country)
                        threeLetterISORegion = getThreeLetterCode(from: country)
                        selectedCountry = country
                    }
                }
        }
    }

    // MARK: - Picker by Platform

    @ViewBuilder
    private func isoPicker(_ title: String, countries: [CountryInfo], selection: Binding<Int>) -> some View {
        #if os(tvOS)
        ListRowMenu(title, subtitle: {
            Text(getDisplayName(for: countries[selection.wrappedValue]))
        }) {
            ForEach(countries.indices, id: \.self) { index in
                let country = countries[index]
                Button(getDisplayName(for: country)) {
                    selection.wrappedValue = index
                }
            }
        }
        .menuStyle(.borderlessButton)
        .listRowInsets(.zero)
        #else
        Picker(title, selection: selection) {
            ForEach(0 ..< countries.count, id: \.self) { index in
                Text(getDisplayName(for: countries[index]))
                    .tag(index)
            }
        }
        #endif
    }

    // MARK: - Update Selection

    private func updateSelectedIndex() {
        guard !countries.isEmpty else { return }

        var twoLetterMap: [String: Int] = [:]
        var threeLetterMap: [String: Int] = [:]

        for (index, country) in countries.enumerated() {
            if let code = getTwoLetterCode(from: country) {
                twoLetterMap[code] = index
            }
            if let code = getThreeLetterCode(from: country) {
                threeLetterMap[code] = index
            }
        }

        // Try to find by selected country
        if let selectedCountry = selectedCountry {
            if let twoLetter = getTwoLetterCode(from: selectedCountry),
               let threeLetter = getThreeLetterCode(from: selectedCountry)
            {

                // Look for exact match with both codes
                for (index, country) in countries.enumerated() {
                    if getTwoLetterCode(from: country) == twoLetter &&
                        getThreeLetterCode(from: country) == threeLetter
                    {
                        selectedIndex = index
                        return
                    }
                }
            }

            // Try just two letter code
            if let twoLetter = getTwoLetterCode(from: selectedCountry),
               let index = twoLetterMap[twoLetter]
            {
                selectedIndex = index
                return
            }

            // Try just three letter code
            if let threeLetter = getThreeLetterCode(from: selectedCountry),
               let index = threeLetterMap[threeLetter]
            {
                selectedIndex = index
                return
            }
        }

        // Try by two letter code
        if let code = twoLetterISORegion, let index = twoLetterMap[code] {
            selectedIndex = index
            return
        }

        // Try by three letter code
        if let code = threeLetterISORegion, let index = threeLetterMap[code] {
            selectedIndex = index
            return
        }

        // Default to first item
        selectedIndex = 0
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

    // MARK: - Get Empty Country Info

    private var emptyCountryInfo: CountryInfo {
        .init(
            displayName: L10n.none,
            name: L10n.none,
            threeLetterISORegionName: nil,
            twoLetterISORegionName: nil
        )
    }
}

extension CountryPicker {

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
