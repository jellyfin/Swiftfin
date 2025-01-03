//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension IdentifyItemView {

    struct RemoteSearchResultView: View {

        // MARK: - Item Info Variables

        let result: RemoteSearchResult

        // MARK: - Item Info Actions

        let onSave: () -> Void
        let onClose: () -> Void

        // MARK: - Body

        @ViewBuilder
        private var header: some View {
            Section {
                HStack(alignment: .bottom, spacing: 12) {
                    IdentifyItemView.resultImage(URL(string: result.imageURL))
                        .frame(width: 100)
                        .accessibilityIgnoresInvertColors()

                    Text(result.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .padding(.bottom)
                }
            }
            .listRowBackground(Color.clear)
            .listRowCornerRadius(0)
            .listRowInsets(.zero)
        }

        @ViewBuilder
        private var resultDetails: some View {
            Section(L10n.details) {

                if let premiereDate = result.premiereDate {
                    TextPairView(
                        L10n.premiereDate,
                        value: Text(premiereDate.formatted(.dateTime.year().month().day()))
                    )
                }

                if let productionYear = result.productionYear {
                    TextPairView(
                        L10n.productionYear,
                        value: Text(productionYear, format: .number.grouping(.never))
                    )
                }

                if let provider = result.searchProviderName {
                    TextPairView(
                        leading: L10n.provider,
                        trailing: provider
                    )
                }

                if let providerID = result.providerIDs?.values.first {
                    TextPairView(
                        leading: L10n.id,
                        trailing: providerID
                    )
                }
            }

            if let overview = result.overview {
                Section(L10n.overview) {
                    Text(overview)
                }
            }
        }

        var body: some View {
            NavigationView {
                List {
                    header

                    resultDetails
                }
                .navigationTitle(L10n.identify)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarCloseButton {
                    onClose()
                }
                .topBarTrailing {
                    Button(L10n.save, action: onSave)
                        .buttonStyle(.toolbarPill)
                }
            }
        }
    }
}
