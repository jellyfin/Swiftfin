//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserParentalRatingView: View {

    @Router
    private var router

    @StateObject
    private var viewModel: ServerUserAdminViewModel
    @StateObject
    private var parentalRatingsViewModel: ParentalRatingsViewModel

    @State
    private var tempPolicy: UserPolicy

    init(viewModel: ServerUserAdminViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._parentalRatingsViewModel = StateObject(wrappedValue: ParentalRatingsViewModel(initialValue: []))

        guard let policy = viewModel.user.policy else {
            preconditionFailure("User policy cannot be empty.")
        }

        self.tempPolicy = policy
    }

    var body: some View {
        List {
            maxParentalRatingsView

            blockUnratedItemsView
        }
        .navigationTitle(L10n.parentalRatings.localizedCapitalized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.is(.updating) {
                ProgressView()
            }

            Button(L10n.save) {
                if tempPolicy != viewModel.user.policy {
                    viewModel.updatePolicy(tempPolicy)
                }
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.user.policy == tempPolicy)
        }
        .onFirstAppear {
            parentalRatingsViewModel.refresh()
        }
        .refreshable {
            parentalRatingsViewModel.refresh()
            viewModel.refresh()
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

    @ViewBuilder
    private var maxParentalRatingsView: some View {
        Section(L10n.maxParentalRating) {
            Picker(L10n.parentalRating, selection: $tempPolicy.maxParentalRating) {
                ForEach(
                    reducedParentalRatings(),
                    id: \.value
                ) { rating in
                    Text(rating.name ?? L10n.unknown)
                        .tag(rating.value)
                }
            }
        } footer: {
            Text(L10n.maxParentalRatingDescription)
        } learnMore: {
            LabeledContent(
                L10n.parentalRating,
                content: parentalRatingLabeledContent
            )
        }
    }

    @ViewBuilder
    private var blockUnratedItemsView: some View {
        Section {
            ForEach(UnratedItem.allCases.sorted(using: \.displayTitle), id: \.self) { item in
                Toggle(
                    item.displayTitle,
                    isOn: $tempPolicy.blockUnratedItems
                        .coalesce([])
                        .contains(item)
                )
            }
        } header: {
            Text(L10n.blockUnratedItems)
        } footer: {
            Text(L10n.blockUnratedItemsDescription)
        }
    }

    private func reducedParentalRatings() -> [ParentalRating] {
        [ParentalRating(name: L10n.none, value: nil)] +
            parentalRatingsViewModel.value.grouped { $0.value ?? 0 }
            .map { key, group in
                if key < 100 {
                    if key == 0 {
                        return ParentalRating(name: L10n.allAudiences, value: key)
                    } else {
                        return ParentalRating(name: L10n.agesGroup(key), value: key)
                    }
                } else {
                    let name = group
                        .compactMap(\.name)
                        .sorted()
                        .joined(separator: " / ")

                    return ParentalRating(name: name, value: key)
                }
            }
            .sorted(using: \.value)
    }

    @LabeledContentBuilder
    private func parentalRatingLabeledContent() -> AnyView {
        let reducedRatings = reducedParentalRatings()
        let groupedRatings = parentalRatingsViewModel.value.grouped { $0.value ?? 0 }

        ForEach(groupedRatings.keys.sorted(), id: \.self) { key in
            if let matchingRating = reducedRatings.first(where: { $0.value == key }) {
                let name = groupedRatings[key]?
                    .compactMap(\.name)
                    .sorted()
                    .joined(separator: "\n") ?? L10n.none

                LabeledContent(matchingRating.name ?? L10n.none) {
                    Text(name)
                }
            }
        }
    }
}
