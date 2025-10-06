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

    // MARK: - State Objects

    @StateObject
    private var viewModel: ParentalRatingsViewModel

    // MARK: - Input Properties

    private var selectionBinding: Binding<ParentalRating?>
    private let title: String

    @State
    private var selection: ParentalRating?

    // MARK: - Body

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
            Picker(title, selection: $selection) {

                Text(ParentalRating.none.displayTitle)
                    .tag(ParentalRating.none as ParentalRating?)

                ForEach(viewModel.value, id: \.self) { value in
                    Text(value.displayTitle)
                        .tag(value as ParentalRating?)
                }
            }
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

    // MARK: - Update Selection

    private func updateSelection() {
        let newValue = viewModel.value.first { value in
            if let selectedName = selection?.name,
               let candidateName = value.name,
               selectedName == candidateName
            {
                return true
            }
            return false
        }

        selection = newValue ?? ParentalRating.none
    }
}

extension ParentalRatingPicker {

    init(_ title: String, name: Binding<String?>) {
        self.title = title
        self._selection = State(
            initialValue: name.wrappedValue.flatMap {
                ParentalRating(name: $0)
            } ?? ParentalRating.none
        )

        self.selectionBinding = Binding<ParentalRating?>(
            get: {
                guard let ratingName = name.wrappedValue else {
                    return ParentalRating.none
                }
                return ParentalRating(name: ratingName)
            },
            set: { newRating in
                name.wrappedValue = newRating?.name
            }
        )

        self._viewModel = StateObject(
            wrappedValue: ParentalRatingsViewModel(
                initialValue: [.none]
            )
        )
    }
}
