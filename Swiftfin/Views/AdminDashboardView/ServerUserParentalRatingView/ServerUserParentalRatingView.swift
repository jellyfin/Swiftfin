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

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    @StateObject
    private var viewModel: ServerUserAdminViewModel
    @ObservedObject
    private var parentalRatingsViewModel = ParentalRatingsViewModel()

    // MARK: - Policy Variable

    @State
    private var tempPolicy: UserPolicy

    // MARK: - Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.tempPolicy = viewModel.user.policy ?? UserPolicy()
    }

    // MARK: - Body

    var body: some View {
        contentView
            .navigationTitle(L10n.parentalRating)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarCloseButton {
                router.dismissCoordinator()
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
                parentalRatingsViewModel.send(.refresh)
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                }
            }
            .errorMessage($error)
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        List {
            maxParentalRatingsView
            blockUnratedItemsView
        }
    }

    // MARK: - Maximum Parental Ratings View

    @ViewBuilder
    var maxParentalRatingsView: some View {
        Section {
            Picker(L10n.parentalRating, selection: $tempPolicy.maxParentalRating) {
                ForEach(parentalRatingGroups, id: \.value) { rating in
                    Text(rating.name ?? L10n.unknown)
                        .tag(rating.value)
                }
            }
        } header: {
            Text(L10n.maxParentalRating)
        } footer: {
            VStack(alignment: .leading) {
                Text(L10n.maxParentalRatingDescription)

                LearnMoreButton(L10n.parentalRating) {
                    parentalRatingLearnMore
                }
            }
        }
    }

    // MARK: - Block Unrated Items View

    @ViewBuilder
    var blockUnratedItemsView: some View {
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

    // MARK: - Parental Rating Groups

    private var parentalRatingGroups: [ParentalRating] {
        let groups = Dictionary(
            grouping: parentalRatingsViewModel.parentalRatings
        ) {
            $0.value ?? 0
        }

        var groupedRatings = groups.map { key, group in
            if key < 100 {
                if key == 0 {
                    return ParentalRating(name: L10n.allAudiences, value: key)
                } else {
                    return ParentalRating(name: L10n.agesGroup(key), value: key)
                }
            } else {
                // Concatenate all 100+ ratings at the same value with '/' but as of 10.10 there should be none.
                let name = group
                    .compactMap(\.name)
                    .sorted()
                    .joined(separator: " / ")

                return ParentalRating(name: name, value: key)
            }
        }
        .sorted(using: \.value)

        let unrated = ParentalRating(name: L10n.none, value: nil)
        groupedRatings.insert(unrated, at: 0)

        return groupedRatings
    }

    // MARK: - Parental Rating Learn More

    private var parentalRatingLearnMore: [TextPair] {
        let groups = Dictionary(
            grouping: parentalRatingsViewModel.parentalRatings
        ) {
            $0.value ?? 0
        }
        .sorted(using: \.key)

        let groupedRatings = groups.compactMap { key, group in
            let matchingRating = parentalRatingGroups.first { $0.value == key }

            let name = group
                .compactMap(\.name)
                .sorted()
                .joined(separator: "\n")

            return TextPair(
                title: matchingRating?.name ?? L10n.none,
                subtitle: name
            )
        }

        return groupedRatings
    }
}
