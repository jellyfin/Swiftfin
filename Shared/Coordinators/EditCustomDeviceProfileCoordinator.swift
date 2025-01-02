//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

final class EditCustomDeviceProfileCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \EditCustomDeviceProfileCoordinator.start)

    @Root
    var start = makeStart

    // TODO: fix for tvOS

    @Route(.push)
    var customDeviceAudioEditor = makeCustomDeviceAudioEditor
    @Route(.push)
    var customDeviceVideoEditor = makeCustomDeviceVideoEditor
    @Route(.push)
    var customDeviceContainerEditor = makeCustomDeviceContainerEditor

    private let profile: Binding<CustomDeviceProfile>?

    init(profile: Binding<CustomDeviceProfile>? = nil) {
        self.profile = profile
    }

    @ViewBuilder
    func makeCustomDeviceAudioEditor(selection: Binding<[AudioCodec]>) -> some View {
        OrderedSectionSelectorView(selection: selection, sources: AudioCodec.allCases)
            .navigationTitle(L10n.audio)
    }

    @ViewBuilder
    func makeCustomDeviceVideoEditor(selection: Binding<[VideoCodec]>) -> some View {
        OrderedSectionSelectorView(selection: selection, sources: VideoCodec.allCases)
            .navigationTitle(L10n.video)
    }

    @ViewBuilder
    func makeCustomDeviceContainerEditor(selection: Binding<[MediaContainer]>) -> some View {
        OrderedSectionSelectorView(selection: selection, sources: MediaContainer.allCases)
            .navigationTitle(L10n.containers)
    }

    @ViewBuilder
    func makeStart() -> some View {
        CustomDeviceProfileSettingsView.EditCustomDeviceProfileView(profile: profile)
            .navigationTitle(L10n.customProfile)
    }
}
