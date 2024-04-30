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
        if let image = viewModel.userSession.user.image {
            Image(uiImage: image)
                .resizable()
        } else {
            ImageView(
                viewModel.userSession.user.profileImageSource(
                    client: viewModel.userSession.client,
                    maxWidth: 120,
                    maxHeight: 120
                )
            )
            .placeholder { _ in
                SystemImageContentView(systemName: "person.fill")
                    .imageFrameRatio(width: 2, height: 2)
            }
            .failure {
                SystemImageContentView(systemName: "person.fill")
                    .imageFrameRatio(width: 2, height: 2)
            }
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .center) {
                    Button {
                        print("here")
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            imageView
                                .frame(width: 150, height: 150)
                                .clipShape(.circle)
                                .shadow(radius: 5)

                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
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
        }
    }
}
