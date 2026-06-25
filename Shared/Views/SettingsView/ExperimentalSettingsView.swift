//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import SwiftUI

/// `Note`: Used for experimental settings that may be removed or implemented officially. Keep for future settings.
struct ExperimentalSettingsView: View {

    #if os(tvOS)
    static let isEnabled = false
    #else
    static let isEnabled = true
    #endif

    @Default(.Experimental.serverConnectionAutoSwitch)
    private var isServerConnectionAutoSwitchEnabled

    @Injected(\.userSessionManager)
    private var userSessionManager: UserSessionManager

    var body: some View {
        Form(systemImage: "flask") {
            // swiftlint:disable hard_coded_display_string
            Toggle("Auto switch connection", isOn: $isServerConnectionAutoSwitchEnabled)

            // swiftlint:enable hard_coded_display_string
        }
        .backport
        .onChange(of: isServerConnectionAutoSwitchEnabled) { _, newValue in
            if newValue {
                userSessionManager.scheduleServerConnectionResolution()
            }
        }
        .navigationTitle(L10n.experimental)
    }
}
