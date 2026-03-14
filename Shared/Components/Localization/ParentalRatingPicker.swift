//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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

    private var currentParentalRating: ParentalRating? {
        viewModel.value.first(property: \.name, equalTo: selection.wrappedValue)
    }

    @ViewBuilder
    private var picker: some View {
        Picker(
            title,
            sources: viewModel.value,
            selection: selection.map(
                getter: { name in viewModel.value.first(property: \.name, equalTo: name) },
                setter: { rating in rating?.name }
            )
        )
    }

    var body: some View {
        Group {
            #if os(tvOS)
            ListRowMenu(
                title,
                subtitle: currentParentalRating?.displayTitle
            ) {
                picker
            }
            .menuStyle(.borderlessButton)
            .listRowInsets(.zero)
            #else
            picker
            #endif
        }
        .enabled(viewModel.state == .initial)
        .onFirstAppear {
            viewModel.refresh()
        }
    }
}
