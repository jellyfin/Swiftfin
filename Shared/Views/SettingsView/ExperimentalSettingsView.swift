//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// `Note`: Used for experimental settings that may be removed or implemented officially. Keep for future settings.
struct ExperimentalSettingsView: View {

    // MARK: - iOS Settings

    #if os(iOS)

    // Enable if `ExperimentalSettingsView` is needed for iOS Settings
    private static let hasPlatformSettings = false

    @ViewBuilder
    private var platformSettings: some View {
        // iOS Specific Experimental Settings Below
    }

    // MARK: - tvOS Settings

    #elseif os(tvOS)

    // Enable if `ExperimentalSettingsView` is needed for tvOS Settings
    private static let hasPlatformSettings = false

    @ViewBuilder
    private var platformSettings: some View {
        // tvOS Specific Experimental Settings Below
    }
    #endif

    // MARK: - Shared Settings

    // Enable if `ExperimentalSettingsView` is needed for Shared Settings
    private static let hasSharedSettings = false

    @ViewBuilder
    private var sharedSettings: some View {
        // Non-OS Specific Experimental Settings Below
    }

    // MARK: - Boilerplate (Do Not Change)

    static var isEnabled: Bool {
        hasPlatformSettings || hasSharedSettings
    }

    var body: some View {
        Form(systemImage: "flask") {

            if Self.hasPlatformSettings {
                Section("Platform") {
                    platformSettings
                }
            }

            if Self.hasSharedSettings {
                Section("Swiftfin") {
                    sharedSettings
                }
            }
        }
        .navigationTitle(L10n.experimental)
    }
}
