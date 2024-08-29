//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

final class CustomDeviceProfileSettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \CustomDeviceProfileSettingsCoordinator.start)

    @Root
    var start = makeStart

    @Route(.modal)
    var customDeviceProfileEditor = makeCustomDeviceProfileEditor
    @Route(.modal)
    var customDeviceAudioEditor = makeCustomDeviceAudioEditor
    @Route(.modal)
    var customDeviceVideoEditor = makeCustomDeviceVideoEditor
    @Route(.modal)
    var customDeviceContainerEditor = makeCustomDeviceContainerEditor

    @ViewBuilder
    func makeCustomDeviceProfileEditor(profile: Binding<PlaybackDeviceProfile>) -> some View {
        CustomDeviceProfileEditorView(profile: profile)
    }

    func makeCustomDeviceAudioEditor(selection: Binding<[AudioCodec]>) -> some View {
        OrderedSectionSelectorView(
            title: L10n.audio,
            selection: selection,
            sources: AudioCodec.allCases,
            image: Image(systemName: "waveform")
        )
    }

    func makeCustomDeviceVideoEditor(selection: Binding<[VideoCodec]>) -> some View {
        OrderedSectionSelectorView(
            title: L10n.video,
            selection: selection,
            sources: VideoCodec.allCases,
            image: Image(systemName: "photo.tv")
        )
    }

    func makeCustomDeviceContainerEditor(selection: Binding<[MediaContainer]>) -> some View {
        OrderedSectionSelectorView(
            title: L10n.containers,
            selection: selection,
            sources: MediaContainer.allCases,
            image: Image(systemName: "shippingbox")
        )
    }

    @ViewBuilder
    func makeStart() -> some View {
        CustomDeviceProfileSettingsView()
            .navigationTitle(L10n.customProfile)
    }
}
