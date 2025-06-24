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

        // MARK: - Router

        @Router
        private var router

        // MARK: - Item Info Variables

        @StateObject
        var viewModel: IdentifyItemViewModel

        let result: RemoteSearchResult

        // MARK: - Error State

        @State
        private var error: Error?

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
                    LabeledContent(
                        L10n.premiereDate,
                        value: premiereDate,
                        format: .dateTime.year().month().day()
                    )
                }

                if let productionYear = result.productionYear {
                    LabeledContent(
                        L10n.productionYear,
                        value: productionYear,
                        format: .number.grouping(.never)
                    )
                }

                if let provider = result.searchProviderName {
                    LabeledContent(
                        L10n.provider,
                        value: provider
                    )
                }

                if let providerID = result.providerIDs?.values.first {
                    LabeledContent(
                        L10n.id,
                        value: providerID
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
            List {
                header

                resultDetails
            }
            .navigationTitle(L10n.identify)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismiss()
            }
            .topBarTrailing {
                Button(L10n.save) {
                    viewModel.send(.update(result))
                }
                .buttonStyle(.toolbarPill)
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                case .cancelled:
                    break
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismiss()
                }
            }
            .errorMessage($error)
        }
    }
}
