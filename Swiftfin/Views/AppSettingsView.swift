//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Stinsen
import SwiftUI

#warning("TODO: break out duration into components")
#warning("TODO: finalize organization")

struct AppSettingsView: View {

    @Default(.accentColor)
    private var accentColor
    @Default(.appearance)
    private var appearance
    @Default(.backgroundSignOutInterval)
    private var backgroundSignOutInterval
    @Default(.signOutOnBackground)
    private var signOutOnBackground
    @Default(.signOutOnClose)
    private var signOutOnClose

    @EnvironmentObject
    private var router: BasicAppSettingsCoordinator.Router

    @State
    private var backgroundSignOutHours: Int
    @State
    private var backgroundSignOutMinutes: Int
    @State
    private var isEditingBackgroundSignOutInterval: Bool = false

    init() {
        let interval = Defaults[.backgroundSignOutInterval]
        _backgroundSignOutHours = State(initialValue: Int(interval) / 3600)
        _backgroundSignOutMinutes = State(initialValue: (Int(interval) % 3600) / 60)
    }

    @StateObject
    private var viewModel = SettingsViewModel()

    var body: some View {
        Form {

            ChevronButton(title: L10n.about)
                .onSelect {
                    router.route(to: \.about, viewModel)
                }

            Section(L10n.accessibility) {

                ChevronButton(title: L10n.appIcon)
                    .onSelect {
                        router.route(to: \.appIconSelector, viewModel)
                    }

                CaseIterablePicker(
                    title: L10n.appearance,
                    selection: $appearance
                )
            }

            Section {
                Toggle("Sign out on close", isOn: $signOutOnClose)
            } footer: {
                Text("Signs out the last user when the app has been closed")
            }

            Section {
                Toggle("Sign out on background", isOn: $signOutOnBackground)
            } footer: {
                Text("Signs out the last user when the app has been in the background for some time")
            }

            if signOutOnBackground {
                Section {
                    HStack {
                        Text("Duration")

                        Spacer()

                        Button {
                            isEditingBackgroundSignOutInterval.toggle()
                        } label: {
                            HStack {
                                Text(backgroundSignOutInterval, format: .hourMinute)
                                    .foregroundStyle(.secondary)

                                Image(systemName: "chevron.right")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(isEditingBackgroundSignOutInterval ? .degrees(90) : .zero)
                                    .animation(.linear(duration: 0.075), value: isEditingBackgroundSignOutInterval)
                            }
                        }
                        .foregroundStyle(.primary, .secondary)
                    }

                    if isEditingBackgroundSignOutInterval {
                        HourMinutePicker(
                            hourSelection: $backgroundSignOutHours,
                            minuteSelection: $backgroundSignOutMinutes
                        )
                    }
                } footer: {
                    if backgroundSignOutInterval == 0 {
                        HStack(alignment: .top) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)

                            Text("The last user will be signed out every time the app enters the background")
                        }
                    }
                }
            }

            ChevronButton(title: L10n.logs)
                .onSelect {
                    router.route(to: \.log)
                }

            // TODO: come up with exact rules and implement
//            ChevronButton(title: "Super User")
        }
        .animation(.linear(duration: 0.15), value: isEditingBackgroundSignOutInterval)
        .navigationTitle(L10n.advanced)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismissCoordinator()
        }
        .onChange(of: backgroundSignOutHours) { newValue in
            let newInterval = Double(newValue * 3600 + backgroundSignOutMinutes * 60)
            backgroundSignOutInterval = newInterval
        }
        .onChange(of: backgroundSignOutMinutes) { newValue in
            let newInterval = Double(backgroundSignOutHours * 3600 + newValue * 60)
            backgroundSignOutInterval = newInterval
        }
    }
}
