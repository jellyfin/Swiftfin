//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreData
import Defaults
import Stinsen
import SwiftUI

struct SettingsView: View {

    @EnvironmentObject
    private var settingsRouter: SettingsCoordinator.Router
    @ObservedObject
    var viewModel: SettingsViewModel

    @Default(.appAppearance)
    var appAppearance
    @Default(.overlayType)
    var overlayType
    @Default(.videoPlayerJumpForward)
    var jumpForwardLength
    @Default(.videoPlayerJumpBackward)
    var jumpBackwardLength
    @Default(.jumpGesturesEnabled)
    var jumpGesturesEnabled
    @Default(.systemControlGesturesEnabled)
    var systemControlGesturesEnabled
    @Default(.playerGesturesLockGestureEnabled)
    var playerGesturesLockGestureEnabled
    @Default(.seekSlideGestureEnabled)
    var seekSlideGestureEnabled
    @Default(.resumeOffset)
    var resumeOffset
    @Default(.subtitleSize)
    var subtitleSize
    @Default(.subtitleFontName)
    var subtitleFontName

    var body: some View {
        Form {
            Section(header: EmptyView()) {
                HStack {
                    L10n.user.text
                    Spacer()
                    Text(viewModel.user.username)
                        .foregroundColor(.jellyfinPurple)
                }

                Button {
                    settingsRouter.route(to: \.serverDetail)
                } label: {
                    HStack {
                        L10n.server.text
                            .foregroundColor(.primary)
                        Spacer()
                        Text(viewModel.server.name)
                            .foregroundColor(.jellyfinPurple)

                        Image(systemName: "chevron.right")
                    }
                }

                Button {
                    settingsRouter.route(to: \.quickConnect)
                } label: {
                    HStack {
                        L10n.quickConnect.text
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }

                Button {
                    settingsRouter.dismissCoordinator {
                        SessionManager.main.logout()
                    }
                } label: {
                    L10n.switchUser.text
                        .font(.callout)
                }
            }

            Section(header: L10n.videoPlayer.text) {
                Picker(L10n.jumpForwardLength, selection: $jumpForwardLength) {
                    ForEach(VideoPlayerJumpLength.allCases, id: \.self) { length in
                        Text(length.label).tag(length.rawValue)
                    }
                }

                Picker(L10n.jumpBackwardLength, selection: $jumpBackwardLength) {
                    ForEach(VideoPlayerJumpLength.allCases, id: \.self) { length in
                        Text(length.label).tag(length.rawValue)
                    }
                }

                Toggle(L10n.jumpGesturesEnabled, isOn: $jumpGesturesEnabled)

                Toggle(L10n.systemControlGesturesEnabled, isOn: $systemControlGesturesEnabled)

                Toggle(L10n.seekSlideGestureEnabled, isOn: $seekSlideGestureEnabled)

                Toggle(L10n.playerGesturesLockGestureEnabled, isOn: $playerGesturesLockGestureEnabled)

                Toggle(L10n.resume5SecondOffset, isOn: $resumeOffset)

                Button {
                    settingsRouter.route(to: \.overlaySettings)
                } label: {
                    HStack {
                        L10n.overlay.text
                            .foregroundColor(.primary)
                        Spacer()
                        Text(overlayType.label)
                        Image(systemName: "chevron.right")
                    }
                }

                Button {
                    settingsRouter.route(to: \.experimentalSettings)
                } label: {
                    HStack {
                        L10n.experimental.text
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
            }

            Section(header: L10n.accessibility.text) {

                Button {
                    settingsRouter.route(to: \.customizeViewsSettings)
                } label: {
                    HStack {
                        L10n.customize.text
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }

                Picker(L10n.appearance, selection: $appAppearance) {
                    ForEach(AppAppearance.allCases, id: \.self) { appearance in
                        Text(appearance.localizedName).tag(appearance.rawValue)
                    }
                }

                Button {
                    settingsRouter.route(to: \.fontPicker)
                } label: {
                    HStack {
                        L10n.subtitleFont.text
                            .foregroundColor(.primary)
                        Spacer()
                        Text(subtitleFontName)
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right")
                    }
                }

                Picker(L10n.subtitleSize, selection: $subtitleSize) {
                    ForEach(SubtitleSize.allCases, id: \.self) { size in
                        Text(size.label).tag(size.rawValue)
                    }
                }
            }

            Button {
                settingsRouter.route(to: \.about)
            } label: {
                HStack {
                    L10n.about.text
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
            }
        }
        .navigationBarTitle(L10n.settings, displayMode: .inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    settingsRouter.dismissCoordinator()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
    }
}
