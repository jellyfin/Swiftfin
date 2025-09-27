//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserParentalRatingView: View {

    // MARK: - Observed, State, & Environment Objects

    @Router
    private var router

    @StateObject
    private var viewModel: ServerUserAdminViewModel
    @StateObject
    private var parentalRatingsViewModel: ParentalRatingsViewModel

    // MARK: - Policy Variable

    @State
    private var tempPolicy: UserPolicy

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._parentalRatingsViewModel = StateObject(wrappedValue: ParentalRatingsViewModel(initialValue: []))

        guard let policy = viewModel.user.policy else {
            preconditionFailure("User policy cannot be empty.")
        }

        self.tempPolicy = policy
    }

    // MARK: - Body

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
            if viewModel.backgroundStates.contains(.updating) {
                ProgressView()
            }

            Button(L10n.save) {
                if tempPolicy != viewModel.user.policy {
                    viewModel.send(.updatePolicy(tempPolicy))
                }
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.user.policy == tempPolicy)
        }
        .onFirstAppear {
            parentalRatingsViewModel.refresh()
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .error(eventError):
                UIDevice.feedback(.error)
                error = eventError
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            }
        }
        .errorMessage($error)
    }

    // MARK: - Maximum Parental Ratings View

    @ViewBuilder
    private var maxParentalRatingsView: some View {
        Section {
            Picker(L10n.parentalRating, selection: $tempPolicy.maxParentalRating) {
                ForEach(
                    reducedParentalRatings(),
                    id: \.value
                ) { rating in
                    Text(rating.name ?? L10n.unknown)
                        .tag(rating.value)
                }
            }
        } header: {
            Text(L10n.maxParentalRating)
        } footer: {
            VStack(alignment: .leading) {
                Text(L10n.maxParentalRatingDescription)

                LearnMoreButton(
                    L10n.parentalRating,
                    content: parentalRatingLabeledContent
                )
            }
        }
    }

    // MARK: - Block Unrated Items View

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

    // MARK: - Parental Rating Learn More

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
