//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Factory
import SwiftUI

struct UserProfileSettingsView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    var viewModel: SettingsViewModel

    @ViewBuilder
    private var imageView: some View {
        ImageView(
            viewModel.userSession.user.profileImageSource(
                client: viewModel.userSession.client,
                maxWidth: 120,
                maxHeight: 120
            )
        )
        .placeholder { _ in
            SystemImageContentView(systemName: "person.fill", ratio: 0.5)
        }
        .failure {
            SystemImageContentView(systemName: "person.fill", ratio: 0.5)
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .center) {
                    Button {
                        // TODO: photo picker
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            imageView
                                .frame(width: 150, height: 150)
                                .clipShape(.circle)
                                .shadow(radius: 5)

                            // TODO: uncomment when photo picker implemented
//                            Image(systemName: "pencil.circle.fill")
//                                .resizable()
//                                .frame(width: 30, height: 30)
                        }
                    }

                    Text(viewModel.userSession.user.username)
                        .fontWeight(.semibold)
                        .font(.title2)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }

            Section {
                ChevronButton(title: L10n.quickConnect)
                    .onSelect {
                        router.route(to: \.quickConnect)
                    }

                ChevronButton(title: "Password")
                    .onSelect {
                        router.route(to: \.resetUserPassword)
                    }
            }

            Section {
                ChevronButton(title: "Local Security")
                    .onSelect {
                        router.route(to: \.localSecurity)
                    }
            }
        }
    }
}
