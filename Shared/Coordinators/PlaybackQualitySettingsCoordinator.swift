//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

final class PlaybackQualitySettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \PlaybackQualitySettingsCoordinator.start)

    @Root
    var start = makeStart

    @Route(.push)
    var customDeviceProfileSettings = makeCustomDeviceProfileSettings

    func makeCustomDeviceProfileSettings() -> NavigationViewCoordinator<CustomDeviceProfileCoordinator> {
        NavigationViewCoordinator(
            CustomDeviceProfileCoordinator()
        )
    }

    func makeEditCustomDeviceProfile(profile: Binding<CustomDeviceProfile>)
    -> NavigationViewCoordinator<EditCustomDeviceProfileCoordinator> {
        NavigationViewCoordinator(EditCustomDeviceProfileCoordinator(profile: profile))
    }

    func makeCreateCustomDeviceProfile() -> NavigationViewCoordinator<EditCustomDeviceProfileCoordinator> {
        NavigationViewCoordinator(EditCustomDeviceProfileCoordinator())
    }

    @ViewBuilder
    func makeStart() -> some View {
        PlaybackQualitySettingsView()
    }
}
