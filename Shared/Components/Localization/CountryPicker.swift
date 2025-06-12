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

    // MARK: - State Objects

    @StateObject
    private var viewModel = CountryViewModel()

    // MARK: - State Variables

    @State
    private var selectedIndex: Int = 0

    // MARK: - Computed Properties

    private var countries: [CountryInfo] {
        [emptyCountryInfo] + Array(viewModel.countries)
            .sorted { getDisplayName(for: $0) < getDisplayName(for: $1) }
    }

    // MARK: - Input Properties

    private let title: String

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
            upgradeSelectedCountryIfNeeded()
            updateSelectedIndex()
        }
        .onChange(of: selectedCountry) { _ in
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
                        selectedCountry = countries[newIndex]
                    }
                }
        }
    }

    // MARK: - ISO Picker

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

    // MARK: Update the Selected Index

    private func updateSelectedIndex() {
        guard !countries.isEmpty else { return }

        if let selectedCountry = selectedCountry {
            let matchingCountry = findMatchingCountry(for: selectedCountry)
            selectedIndex = countries.firstIndex(where: { areEqual($0, matchingCountry) }) ?? 0
        } else {
            selectedIndex = 0
        }
    }

    // MARK: Turn Incomplete CountryInfo into Full Matching CountryInfo

    private func upgradeSelectedCountryIfNeeded() {
        guard let currentSelected = selectedCountry else { return }

        if let upgradeCandidate = findMatchingCountry(for: currentSelected),
           !areEqual(upgradeCandidate, currentSelected)
        {
            selectedCountry = upgradeCandidate
        }
    }

    // MARK: - Find a Matching CountryInfo from Potentially Incomplete CountryInfo

    private func findMatchingCountry(for country: CountryInfo) -> CountryInfo? {
        countries.first { candidate in
            if let selectedTwo = country.twoLetterISORegionName,
               let candidateTwo = candidate.twoLetterISORegionName,
               selectedTwo == candidateTwo
            {
                return true
            }
            if let selectedThree = country.threeLetterISORegionName,
               let candidateThree = candidate.threeLetterISORegionName,
               selectedThree == candidateThree
            {
                return true
            }
            return false
        }
    }

    // MARK: - Determine if Two Countries are Equal from Potentially Incomplete CountryInfo

    private func areEqual(_ country1: CountryInfo?, _ country2: CountryInfo?) -> Bool {
        guard let country1 = country1, let country2 = country2 else {
            return country1 == nil && country2 == nil
        }

        return country1.twoLetterISORegionName == country2.twoLetterISORegionName &&
            country1.threeLetterISORegionName == country2.threeLetterISORegionName
    }

    // MARK: - Get Country Display Name

    private func getDisplayName(for country: CountryInfo) -> String {
        country.displayName ?? country.name ?? L10n.unknown
    }

    // MARK: - Empty Country Info

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

    // MARK: - Standard Initializer

    init(_ title: String, selectedCountry: Binding<CountryInfo?>) {
        self.title = title
        self._selectedCountry = selectedCountry
    }

    // MARK: - Two Letter Initializer

    init(_ title: String, twoLetterISORegion: Binding<String?>) {
        self.title = title
        self._selectedCountry = Binding(
            get: {
                guard let code = twoLetterISORegion.wrappedValue else { return nil }
                return CountryInfo(
                    displayName: nil,
                    name: nil,
                    threeLetterISORegionName: nil,
                    twoLetterISORegionName: code
                )
            },
            set: { newCountry in
                twoLetterISORegion.wrappedValue = newCountry?.twoLetterISORegionName
            }
        )
    }

    // MARK: - Three Letter Initializer

    init(_ title: String, threeLetterISORegion: Binding<String?>) {
        self.title = title
        self._selectedCountry = Binding(
            get: {
                guard let code = threeLetterISORegion.wrappedValue else { return nil }
                return CountryInfo(
                    displayName: nil,
                    name: nil,
                    threeLetterISORegionName: code,
                    twoLetterISORegionName: nil
                )
            },
            set: { newCountry in
                threeLetterISORegion.wrappedValue = newCountry?.threeLetterISORegionName
            }
        )
    }
}
