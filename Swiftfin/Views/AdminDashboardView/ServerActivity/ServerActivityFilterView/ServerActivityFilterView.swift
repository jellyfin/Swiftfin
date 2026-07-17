//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

struct ServerActivityFilterView: View {

    // MARK: - Environment Objects

    @Router
    private var router

    private let environment: Binding<ServerActivityLibrary.Environment>

    // MARK: - Dialog States

    @State
    private var tempDate: Date

    // MARK: - Initializer

    init(environment: Binding<ServerActivityLibrary.Environment>) {
        self.environment = environment
        self.tempDate = environment.wrappedValue.minDate ?? .now
    }

    // MARK: - Body

    var body: some View {
        List {
            Section {
                DatePicker(
                    L10n.date,
                    selection: $tempDate,
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
            }

            /// Reset button to remove the filter
            if environment.wrappedValue.minDate != nil {
                Section {
                    Button(role: .destructive) {
                        environment.wrappedValue.minDate = nil
                        router.dismiss()
                    } label: {
                        Text(L10n.reset)
                            .frame(maxWidth: .infinity)
                    }
                    .listRowInsets(.zero)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .fontWeight(.semibold)
                    .backport
                    .buttonStyle(.glassProminent.shadow(false))
                    .controlSize(.large)
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
                .startOfDay(for: tempDate)

            let saveAction: () -> Void = {
                environment.wrappedValue.minDate = startOfDay
                router.dismiss()
            }

            Group {
                if #available(iOS 26, *), Defaults[.isLiquidGlassEnabled] {
                    Button(L10n.save, role: .confirm, action: saveAction)
                } else {
                    Button(L10n.save, action: saveAction)
                        .backport
                        .buttonStyle(.glassProminent)
                        .controlSize(.small)
                }
            }
            .disabled(environment.wrappedValue.minDate != nil && startOfDay == environment.wrappedValue.minDate)
        }
    }
}
