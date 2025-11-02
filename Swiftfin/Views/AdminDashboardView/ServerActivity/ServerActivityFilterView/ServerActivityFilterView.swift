//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import JellyfinAPI
import SwiftUI

struct ServerActivityFilterView: View {

    // MARK: - Environment Objects

    @Router
    private var router

    // MARK: - State Objects

    @ObservedObject
    private var viewModel: ServerActivityViewModel

    // MARK: - Dialog States

    @State
    private var tempDate: Date?

    // MARK: - Initializer

    init(viewModel: ServerActivityViewModel) {

        self.viewModel = viewModel

        if let minDate = viewModel.minDate {
            tempDate = minDate
        } else {
            tempDate = .now
        }
    }

    // MARK: - Body

    var body: some View {
        List {
            Section {
                DatePicker(
                    L10n.date,
                    selection: $tempDate.coalesce(.now),
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }

            /// Reset button to remove the filter
            if viewModel.minDate != nil {
                Section {
                    ListRowButton(L10n.reset, role: .destructive) {
                        viewModel.minDate = nil
                        router.dismiss()
                    }
                } footer: {
                    Text(L10n.resetFilterFooter)
                }
            }
        }
        .navigationTitle(L10n.startDate.localizedCapitalized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            let startOfDay = Calendar.current
                .startOfDay(for: tempDate ?? .now)

            Button(L10n.save) {
                viewModel.minDate = startOfDay
                router.dismiss()
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.minDate != nil && startOfDay == viewModel.minDate)
        }
    }
}
