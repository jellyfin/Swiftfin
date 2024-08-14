//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

final class PlaybackQualitySettingsCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \PlaybackQualitySettingsCoordinator.start)

    @Root
    var start = makeStart

    @Route(.modal)
    var customProfileAudioSelector = makeCustomProfileAudioSelector
    @Route(.modal)
    var customProfileVideoSelector = makeCustomProfileVideoSelector
    @Route(.modal)
    var customProfileContainerSelector = makeCustomProfileContainerSelector

    func makeCustomProfileAudioSelector(selection: Binding<[AudioCodec]>) -> some View {
        OrderedSectionSelectorView(
            title: L10n.audio,
            selection: selection,
            sources: AudioCodec.allCases,
            image: Image(systemName: "waveform")
        )
    }

    func makeCustomProfileVideoSelector(selection: Binding<[VideoCodec]>) -> some View {
        OrderedSectionSelectorView(
            title: L10n.video,
            selection: selection,
            sources: VideoCodec.allCases,
            image: Image(systemName: "photo.tv")
        )
    }

    func makeCustomProfileContainerSelector(selection: Binding<[MediaContainer]>) -> some View {
        OrderedSectionSelectorView(
            title: L10n.containers,
            selection: selection,
            sources: MediaContainer.allCases,
            image: Image(systemName: "shippingbox")
        )
    }

    @ViewBuilder
    func makeStart() -> some View {
        PlaybackQualitySettingsView()
    }
}
