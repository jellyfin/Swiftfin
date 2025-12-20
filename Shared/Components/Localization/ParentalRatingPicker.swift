//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct ParentalRatingPicker: View {

    @StateObject
    private var viewModel: ParentalRatingsViewModel

    private let selection: Binding<String?>
    private let title: String

    init(_ title: String, name: Binding<String?>) {
        self.selection = name
        self.title = title
        self._viewModel = .init(wrappedValue: .init(initialValue: []))
    }

    var body: some View {
        Group {
            #if os(tvOS)
            ListRowMenu(title, subtitle: $selection.wrappedValue?.displayTitle) {
                Picker(title, selection: $selection) {
                    Text(ParentalRating.none.displayTitle)
                        .tag(ParentalRating.none as ParentalRating?)

                    ForEach(viewModel.value, id: \.self) { value in
                        Text(value.displayTitle)
                            .tag(value as ParentalRating?)
                    }
                }
            }
            .onChange(of: viewModel.value) {
                updateSelection()
            }
            .onChange(of: selection) { _, newValue in
                selectionBinding.wrappedValue = newValue
            }
            .menuStyle(.borderlessButton)
            .listRowInsets(.zero)
            #else
            Picker(
                title,
                sources: viewModel.value,
                selection: selection.map(
                    getter: { name in viewModel.value.first(property: \.name, equalTo: name) },
                    setter: { rating in rating?.name }
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
