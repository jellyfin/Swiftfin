//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension AppSettingsView {

    struct SignOutIntervalSection: View {

        @Default(.backgroundSignOutInterval)
        private var backgroundSignOutInterval
        @Default(.signOutOnBackground)
        private var signOutOnBackground
        @Default(.signOutOnClose)
        private var signOutOnClose

        @State
        private var isEditingBackgroundSignOutInterval: Bool = false

        var body: some View {
            Section {
                Toggle(L10n.signoutClose, isOn: $signOutOnClose)
            } footer: {
                Text(L10n.signoutCloseFooter)
            }

            Section {
                Toggle(L10n.signoutBackground, isOn: $signOutOnBackground)

                if signOutOnBackground {
                    HStack {
                        Text(L10n.duration)

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
                        HourMinutePicker(interval: $backgroundSignOutInterval)
                    }
                }
            } footer: {
                Text(
                    L10n.signoutBackgroundFooter
                )
            }
            .animation(.linear(duration: 0.15), value: isEditingBackgroundSignOutInterval)
        }
    }
}
