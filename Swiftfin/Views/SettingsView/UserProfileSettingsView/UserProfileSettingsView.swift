//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

struct UserProfileSettingsView: View {

    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    var viewModel: SettingsViewModel

    @State
    private var isPresentingConfirmReset: Bool = false
    @State
    private var isPresentingProfileImageOptions: Bool = false

    @ViewBuilder
    private var imageView: some View {
        RedrawOnNotificationView(.didChangeUserProfileImage) {
            ImageView(
                viewModel.userSession.user.profileImageSource(
                    client: viewModel.userSession.client,
                    maxWidth: 120
                )
            )
            .pipeline(.Swiftfin.branding)
            .image { image in
                image.posterBorder(ratio: 1 / 2, of: \.width)
            }
            .placeholder { _ in
                SystemImageContentView(systemName: "person.fill", ratio: 0.5)
            }
            .failure {
                SystemImageContentView(systemName: "person.fill", ratio: 0.5)
            }
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .center) {
                    Button {
                        isPresentingProfileImageOptions = true
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            // `.aspectRatio(contentMode: .fill)` on `imageView` alone
                            // causes a crash on some iOS versions
                            ZStack {
                                imageView
                            }
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(.circle)
                            .frame(width: 150, height: 150)
                            .shadow(radius: 5)

                            Image(systemName: "pencil.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .shadow(radius: 10)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(accentColor.overlayColor, accentColor)
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
                ChevronButton(L10n.quickConnect)
                    .onSelect {
                        router.route(to: \.quickConnect)
                    }

                ChevronButton("Password")
                    .onSelect {
                        router.route(to: \.resetUserPassword, viewModel.userSession.user.id)
                    }
            }

            Section {
                ChevronButton("Security")
                    .onSelect {
                        router.route(to: \.localSecurity)
                    }
            }

            Section {
                // TODO: move under future "Storage" tab
                //       when downloads implemented
                Button("Reset Settings") {
                    isPresentingConfirmReset = true
                }
                .foregroundStyle(.red)
            } footer: {
                Text("Reset Swiftfin user settings")
            }
        }
        .alert("Reset Settings", isPresented: $isPresentingConfirmReset) {
            Button("Reset", role: .destructive) {
                do {
                    try viewModel.userSession.user.deleteSettings()
                } catch {
                    viewModel.logger.error("Unable to reset user settings: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Are you sure you want to reset all user settings?")
        }
        .confirmationDialog(
            "Profile Image",
            isPresented: $isPresentingProfileImageOptions,
            titleVisibility: .visible
        ) {

            Button("Select Image") {
                router.route(to: \.photoPicker, viewModel)
            }

            Button("Delete", role: .destructive) {
                viewModel.deleteCurrentUserProfileImage()
            }
        }
    }
}
