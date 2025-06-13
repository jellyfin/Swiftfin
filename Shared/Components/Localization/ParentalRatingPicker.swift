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
            ListRowMenu(title, subtitle: selection?.name ?? L10n.none) {
                Picker(title, selection: $selection) {
                    Text(L10n.none)
                        .tag(nil as ParentalRating?)

                    ForEach(viewModel.value, id: \.self) { value in
                        Text(value.name ?? L10n.unknown)
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

                Text(L10n.none)
                    .tag(nil as ParentalRating?)

                ForEach(viewModel.value, id: \.self) { value in
                    Text(value.name ?? L10n.unknown)
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
            viewModel.send(.refresh)
        }
        .onAppear {
            updateSelection()
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

        selection = newValue
    }
}

// MARK: - Initializers

extension ParentalRatingPicker {

    init(_ title: String, selection: Binding<ParentalRating?>) {
        self.title = title
        self._selection = State(initialValue: selection.wrappedValue)
        self.selectionBinding = selection
        self._viewModel = StateObject(wrappedValue: ParentalRatingsViewModel(initialValue: []))
    }

    init(_ title: String, selection: Binding<String?>) {
        self.title = title
        self._selection = State(
            initialValue: selection.wrappedValue.flatMap { ParentalRating(name: $0) }
        )

        self.selectionBinding = Binding<ParentalRating?>(
            get: {
                guard let ratingName = selection.wrappedValue else { return nil }
                return ParentalRating(name: ratingName)
            },
            set: { newRating in
                selection.wrappedValue = newRating?.name
            }
        )

        self._viewModel = StateObject(wrappedValue: ParentalRatingsViewModel(initialValue: []))
    }
}
