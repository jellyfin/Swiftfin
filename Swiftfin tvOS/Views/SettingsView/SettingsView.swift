//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import SwiftUI

struct SettingsView: View {

    @Default(.VideoPlayer.videoPlayerType)
    private var videoPlayerType

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @ObservedObject
    var viewModel: SettingsViewModel

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                Image(.jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                Section {

                    Button {} label: {
                        TextPairView(
                            leading: L10n.user,
                            trailing: viewModel.userSession.user.username
                        )
                    }

                    ChevronButton(
                        title: L10n.server,
                        subtitle: viewModel.userSession.server.name
                    )
                    .onSelect {
                        router.route(to: \.serverDetail, viewModel.userSession.server)
                    }

                    Button {
                        viewModel.signOut()
                    } label: {
                        L10n.switchUser.text
                            .foregroundColor(.jellyfinPurple)
                    }
                }

                Section {

                    InlineEnumToggle(title: "Video Player Type", selection: $videoPlayerType)

                    ChevronButton(title: L10n.videoPlayer)
                        .onSelect {
                            router.route(to: \.videoPlayerSettings)
                        }
                } header: {
                    L10n.videoPlayer.text
                }

                Section {

                    ChevronButton(title: L10n.customize)
                        .onSelect {
                            router.route(to: \.customizeViewsSettings)
                        }

                    ChevronButton(title: L10n.experimental)
                        .onSelect {
                            router.route(to: \.experimentalSettings)
                        }

                } header: {
                    L10n.accessibility.text
                }

                Section {

                    ChevronButton(title: "Logs")
                        .onSelect {
                            router.route(to: \.log)
                        }
                }
            }
    }
}
