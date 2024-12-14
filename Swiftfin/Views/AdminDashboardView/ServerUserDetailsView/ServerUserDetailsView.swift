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

struct ServerUserDetailsView: View {
    @EnvironmentObject
    private var router: AdminDashboardCoordinator.Router

    @CurrentDate
    private var currentDate: Date

    @StateObject
    private var viewModel: ServerUserAdminViewModel

    // MARK: - Initializer

    init(user: UserDto) {
        _viewModel = StateObject(wrappedValue: ServerUserAdminViewModel(user: user))
    }

    // MARK: - Body

    var body: some View {
        List {
            // TODO: Replace with Update Profile Picture & Username
            AdminDashboardView.UserSection(
                user: viewModel.user,
                lastActivityDate: viewModel.user.lastActivityDate
            )

            Section {
                if let userId = viewModel.user.id {
                    ChevronButton(L10n.password)
                        .onSelect {
                            router.route(to: \.resetUserPassword, userId)
                        }
                }
            }

            Section(L10n.advanced) {
                ChevronButton(L10n.permissions)
                    .onSelect {
                        router.route(to: \.userPermissions, viewModel)
                    }
            }

            Section(L10n.access) {
                ChevronButton(L10n.devices)
                    .onSelect {
                        router.route(to: \.userDeviceAccess, viewModel)
                    }
                ChevronButton(L10n.liveTV)
                    .onSelect {
                        router.route(to: \.userLiveTVAccess, viewModel)
                    }
                ChevronButton(L10n.media)
                    .onSelect {
                        router.route(to: \.userMediaAccess, viewModel)
                    }
            }

            Section(L10n.parentalControls) {
                ChevronButton(L10n.accessSchedules)
                    .onSelect {
                        router.route(to: \.userEditAccessSchedules, viewModel)
                    }
                // TODO: Allow items SDK 10.10 - allowedTags
                /* ChevronButton("Allow items")
                      .onSelect {
                          router.route(to: \.userAllowedTags, viewModel)
                      }
                  // TODO: Block items - blockedTags
                 ChevronButton("Block items")
                      .onSelect {
                          router.route(to: \.userBlockedTags, viewModel)
                      } */
                ChevronButton(L10n.ratings)
                    .onSelect {
                        router.route(to: \.userParentalRatings, viewModel)
                    }
            }
        }
        .navigationTitle(L10n.user)
        .onAppear {
            viewModel.send(.loadDetails)
        }
    }
}
