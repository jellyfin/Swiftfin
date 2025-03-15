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
    @Default(.accentColor)
    private var accentColor

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    @StateObject
    private var viewModel = SettingsViewModel()

    struct NamedColor: Hashable {
        let name: String
        let value: Color

        static let availableColors: [NamedColor] = [
            NamedColor(name: L10n.jellyfin, value: .jellyfinPurple),
            NamedColor(name: L10n.red, value: .red),
            NamedColor(name: L10n.orange, value: .orange),
            NamedColor(name: L10n.yellow, value: .yellow),
            NamedColor(name: L10n.green, value: .green),
            NamedColor(name: L10n.blue, value: .blue),
        ]
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
                        router.route(to: \.userProfile, viewModel)
                    }

                    ChevronButton(
                        L10n.server,
                        subtitle: viewModel.userSession.server.name
                    )
                    .onSelect {
                        router.route(to: \.serverDetail, viewModel.userSession.server)
                    }
                }

                Section {
                    ListRowButton(L10n.switchUser) {
                        viewModel.signOut()
                    }
                    .foregroundStyle(accentColor.overlayColor, accentColor)
                    .listRowInsets(.zero)
                }

                Section(L10n.videoPlayer) {

                    InlineEnumToggle(title: L10n.videoPlayerType, selection: $videoPlayerType)

                    ChevronButton(L10n.videoPlayer)
                        .onSelect {
                            router.route(to: \.videoPlayerSettings)
                        }

                    ChevronButton(L10n.playbackQuality)
                        .onSelect {
                            router.route(to: \.playbackQualitySettings)
                        }
                }

                Section(L10n.accessibility) {

                    ChevronButton(L10n.customize)
                        .onSelect {
                            router.route(to: \.customizeViewsSettings)
                        }
//
//                    ChevronButton(L10n.experimental)
//                        .onSelect {
//                            router.route(to: \.experimentalSettings)
//                        }
                }

                Section(L10n.appearance) {
                    Menu {
                        ForEach(NamedColor.availableColors, id: \.self) { color in
                            Button(action: {
                                guard accentColor != color.value else { return }
                                accentColor = color.value
                            }) {
                                Text(color.name)
                                    .foregroundColor(.primary)
                            }
                        }
                    } label: {
                        HStack {
                            Text(L10n.accentColor)
                            Spacer()
                            Circle()
                                .fill(accentColor)
                                .frame(width: 16, height: 16)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.zero)
                    .foregroundStyle(.primary, .secondary)
                }

                Section {

                    ChevronButton(L10n.logs)
                        .onSelect {
                            router.route(to: \.log)
                        }
                }
            }
    }
}
