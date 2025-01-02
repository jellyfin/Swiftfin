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
                Toggle("Sign out on close", isOn: $signOutOnClose)
            } footer: {
                Text("Signs out the last user when Swiftfin has been force closed")
            }

            Section {
                Toggle("Sign out on background", isOn: $signOutOnBackground)

                if signOutOnBackground {
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
                        HourMinutePicker(interval: $backgroundSignOutInterval)
                    }
                }
            } footer: {
                Text(
                    "Signs out the last user when Swiftfin has been in the background without media playback after some time"
                )
            }
            .animation(.linear(duration: 0.15), value: isEditingBackgroundSignOutInterval)
        }
    }
}
