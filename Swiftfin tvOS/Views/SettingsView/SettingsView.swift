//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct SettingsView: View {

    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

    @Default(.defaultUserID)
    private var defaultUserID

    @Router
    private var router

    @StateObject
    private var viewModel = SettingsViewModel()

    @Injected(\.currentUserSession)
    private var currentUserSession

    private var isCurrentUserDefault: Bool {
        if let currentUser = currentUserSession?.user.id,
           case let .signedIn(defaultUser) = defaultUserID
        {
            return currentUser == defaultUser
        }
        return false
    }

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(.jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                Section(L10n.jellyfin) {

                    UserProfileRow(user: viewModel.userSession.user.data) {
                        router.route(to: .userProfile(viewModel: viewModel))
                    }

                    ChevronButton(
                        L10n.server,
                        action: {
                            router.route(to: .editServer(server: viewModel.userSession.server))
                        },
                        icon: { EmptyView() },
                        subtitle: {
                            Label {
                                Text(viewModel.userSession.server.name)
                            } icon: {
                                if !viewModel.userSession.server.isVersionCompatible {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    )
                }

                Section {
                    ListRowButton(L10n.switchUser) {
                        viewModel.signOut()
                    }
                    .foregroundStyle(Color.jellyfinPurple.overlayColor, Color.jellyfinPurple)
                    .listRowInsets(.zero)
                }

                Section {
                    Toggle("Set as Default User", isOn: Binding(
                        get: { isCurrentUserDefault },
                        set: { isOn in
                            if isOn, let currentUser = currentUserSession?.user.id {
                                defaultUserID = .signedIn(userID: currentUser)
                            } else {
                                defaultUserID = .signedOut
                            }
                        }
                    ))
                } header: {
                    Text("Default User")
                } footer: {
                    Text("When enabled, this user will be automatically signed in when the app starts, skipping the user selection screen.")
                }

                if case .signedIn = defaultUserID {
                    Section {
                        ChevronButton("Go to User Selection") {
                            viewModel.signOut()
                        }
                    } footer: {
                        Text("Switch to a different user or manage your accounts.")
                    }
                }

                Section(L10n.videoPlayer) {

                    ListRowMenu(L10n.videoPlayerType, selection: $videoPlayerType)

                    ChevronButton(L10n.videoPlayer) {
                        router.route(to: .videoPlayerSettings)
                    }

                    ChevronButton(L10n.playbackQuality) {
                        router.route(to: .playbackQualitySettings)
                    }
                }

                Section(L10n.accessibility) {

                    ChevronButton(L10n.customize) {
                        router.route(to: .customizeViewsSettings)
                    }
//
//                    ChevronButton(L10n.experimental)
//                        .onSelect {
//                            router.route(to: \.experimentalSettings)
//                        }
                }

                Section {

                    ChevronButton(L10n.logs) {
                        router.route(to: .log)
                    }
                }
            }
    }
}
