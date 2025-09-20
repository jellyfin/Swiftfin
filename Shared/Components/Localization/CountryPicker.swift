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
        Group {
            #if os(tvOS)
            ListRowMenu(title, subtitle: $selection.wrappedValue?.displayTitle) {
                Picker(title, selection: $selection) {
                    Text(CountryInfo.none.displayTitle)
                        .tag(CountryInfo.none as CountryInfo?)

                    ForEach(viewModel.value, id: \.self) { country in
                        Text(country.displayTitle)
                            .tag(country as CountryInfo?)
                    }
                }
            }
            // TODO: iOS 17+ move this to the Group
            .onChange(of: viewModel.value) {
                updateSelection()
            }
            .onChange(of: selection) { _, newValue in
                selectionBinding.wrappedValue = newValue
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
            // TODO: iOS 17+ delete this and use the tvOS onChange at the Group level
            .onChange(of: viewModel.value) { _ in
                updateSelection()
            }
            .onChange(of: selection) { newValue in
                selectionBinding.wrappedValue = newValue
            }
            #endif
        }
        .onFirstAppear {
            viewModel.refresh()
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
