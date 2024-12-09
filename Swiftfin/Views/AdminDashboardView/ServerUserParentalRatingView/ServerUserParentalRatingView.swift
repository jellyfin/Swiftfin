//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ServerUserParentalRatingView: View {

    // MARK: - Environment

    @EnvironmentObject
    private var router: BasicNavigationViewCoordinator.Router

    // MARK: - ViewModel

    @ObservedObject
    private var viewModel: ServerUserAdminViewModel
    @ObservedObject
    private var parentalRatingsViewModel = ParentalRatingsViewModel()

    // MARK: - State Variables

    @State
    private var tempPolicy: UserPolicy
    @State
    private var error: Error?
    @State
    private var isPresentingError: Bool = false

    // MARK: - Initializer

    init(viewModel: ServerUserAdminViewModel) {
        self.viewModel = viewModel
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
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    UIDevice.feedback(.error)
                    error = eventError
                    isPresentingError = true
                case .updated:
                    UIDevice.feedback(.success)
                    router.dismissCoordinator()
                }
            }
            .alert(
                L10n.error.text,
                isPresented: $isPresentingError,
                presenting: error
            ) { _ in
                Button(L10n.dismiss, role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
            .onFirstAppear {
                parentalRatingsViewModel.send(.refresh)
            }
    }

    // MARK: - Content View

    @ViewBuilder
    var contentView: some View {
        List {
            maxParentalRatingsView
            blockUnratedItemsView
        }
    }

    // MARK: - Block Unrated Items View

    @ViewBuilder
    var blockUnratedItemsView: some View {
        Section {
            ForEach(UnratedItem.allCases, id: \.self) { item in
                Toggle(
                    item.rawValue,
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

    // MARK: - Maximum Parental Ratings Toggle View

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
            Text(L10n.maxParentalRatingDescription)
        }
    }

    // MARK: - Parental Rating Groups

    private var parentalRatingGroups: [ParentalRating] {
        let groups = Dictionary(
            grouping: parentalRatingsViewModel.parentalRatings
        ) {
            $0.value!
        }

        var groupedRatings = groups.map { key, group in
            let names = group
                .compactMap(\.name)
                .sorted()
                .joined(separator: " / ")

            return ParentalRating(name: names, value: key)
        }
        .sorted { $0.value ?? 0 < $1.value ?? 0 }

        let unrated = ParentalRating(name: L10n.none, value: nil)
        groupedRatings.insert(unrated, at: 0)

        return groupedRatings
    }
}
