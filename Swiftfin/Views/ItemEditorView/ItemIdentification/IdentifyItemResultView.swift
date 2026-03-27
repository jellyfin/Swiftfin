//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct IdentifyItemResultView: View {

    @ObservedObject
    var viewModel: IdentifyItemViewModel

    @Router
    private var router

    let result: RemoteSearchResult

    var body: some View {
        List {
            FormItemSection(item: result)

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
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.identify)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.is(.updating) {
                ProgressView()
            }

            Button(L10n.save) {
                viewModel.update(result)
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.background.is(.updating))
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
    }
}
