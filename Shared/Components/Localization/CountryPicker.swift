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

    @StateObject
    private var viewModel: CountriesViewModel

    private let selection: Binding<String?>
    private let title: String

    init(_ title: String, twoLetterISORegion: Binding<String?>) {
        self.selection = twoLetterISORegion
        self.title = title
        self._viewModel = .init(wrappedValue: .init(initialValue: []))
    }

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
            .menuStyle(.borderlessButton)
            .listRowInsets(.zero)
            #else
            Picker(
                title,
                sources: viewModel.value,
                selection: selection.map(
                    getter: { iso in viewModel.value.first(property: \.twoLetterISORegionName, equalTo: iso) },
                    setter: { info in info?.twoLetterISORegionName }
                )
            )
            #endif
        }
        .enabled(viewModel.state == .initial)
        .onFirstAppear {
            viewModel.refresh()
        }
    }
}
