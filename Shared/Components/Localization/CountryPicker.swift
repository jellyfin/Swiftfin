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
    private var viewModel: PagingLibraryViewModel<CountryLibrary>

    // MARK: - Input Properties

    private let selection: Binding<String?>
    private let title: String

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
            .menuStyle(.borderlessButton)
            .listRowInsets(.zero)
            #else
            Picker(
                title,
                sources: viewModel.elements,
                selection: selection.map(
                    getter: { iso in viewModel.elements.first(property: \.twoLetterISORegionName, equalTo: iso) },
                    setter: { info in info?.twoLetterISORegionName }
                )
            )
            #endif
        }
        .enabled(viewModel.state == .content)
        .onFirstAppear {
            viewModel.refresh()
        }
    }
}

extension CountryPicker {

    init(_ title: String, twoLetterISORegion: Binding<String?>) {

        self.selection = twoLetterISORegion
        self.title = title
        self._viewModel = .init(wrappedValue: .init(library: .init()))
    }
}
