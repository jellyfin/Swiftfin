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

    @Router
    private var router

    @State
    private var activeDate: Date

    private let environmentBinding: Binding<ServerActivityLibrary.Environment>

    init(environment: Binding<ServerActivityLibrary.Environment>) {
        self.environmentBinding = environment
        self.activeDate = environment.wrappedValue.minDate ?? .now
    }

    var body: some View {
        List {
            Section {
                DatePicker(
                    L10n.date,
                    selection: $activeDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }

            /// Reset button to remove the filter
            if viewModel.minDate != nil {
                Section {
                    Button(L10n.reset, role: .destructive) {
                        viewModel.minDate = nil
                        router.dismiss()
                    }
                    .buttonStyle(.primary)
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
                .startOfDay(for: activeDate)

            Button(L10n.save) {
                environmentBinding.wrappedValue.minDate = startOfDay
                router.dismiss()
            }
            .buttonStyle(.toolbarPill)
            .disabled(activeDate == environmentBinding.wrappedValue.minDate)
//            .disabled(viewModel.minDate != nil && startOfDay == viewModel.minDate)
        }
    }
}
