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
    private var viewModel: CountriesViewModel

    // MARK: - Input Properties

    private var selectionBinding: Binding<CountryInfo?>
    private let title: String

    @State
    private var selection: CountryInfo?

    // MARK: - Body

    var body: some View {
        ZStack {
            #if os(tvOS)
            ListRowMenu(title, subtitle: {
                Text(getDisplayName(for: selection.wrappedValue))
            }) {
                ForEach(countries, id: \.self) { country in
                    Button(getDisplayName(for: country)) {
                        selection.wrappedValue = country.isEmptyCountry ? nil : country
                    }
                }
            }
            .menuStyle(.borderlessButton)
            .listRowInsets(.zero)
            #else
            Picker(title, selection: $selection) {

                Text(CountryInfo.none.displayTitle)
                    .tag(CountryInfo.none as CountryInfo?)

                ForEach(viewModel.value, id: \.self) { country in
                    Text(country.displayTitle)
                        .tag(country as CountryInfo?)
                }
            }
            #endif
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .onChange(of: viewModel.value) { _ in
            updateSelection()
        }
        .onChange(of: selection) { newValue in
            selectionBinding.wrappedValue = newValue
        }
    }

    private func updateSelection() {
        let newValue = viewModel.value.first { value in
            if let selectedTwo = selection?.twoLetterISORegionName,
               let candidateTwo = value.twoLetterISORegionName,
               selectedTwo == candidateTwo
            {
                return true
            }
            if let selectedThree = selection?.threeLetterISORegionName,
               let candidateThree = value.threeLetterISORegionName,
               selectedThree == candidateThree
            {
                return true
            }
            return false
        }

        selection = newValue ?? CountryInfo.none
    }
}

extension CountryPicker {

    init(_ title: String, twoLetterISORegion: Binding<String?>) {
        self.title = title
        self._selection = State(
            initialValue: twoLetterISORegion.wrappedValue.flatMap { code in
                CountryInfo(
                    name: code,
                    twoLetterISORegionName: code
                )
            } ?? CountryInfo.none
        )
        self.selectionBinding = Binding(
            get: {
                guard let code = twoLetterISORegion.wrappedValue else {
                    return CountryInfo.none
                }
                return CountryInfo(
                    name: code,
                    twoLetterISORegionName: code
                )
            },
            set: { newCountry in
                twoLetterISORegion.wrappedValue = newCountry?.twoLetterISORegionName
            }
        )

        self._viewModel = StateObject(
            wrappedValue: CountriesViewModel(
                initialValue: [.none]
            )
        )
    }
}
