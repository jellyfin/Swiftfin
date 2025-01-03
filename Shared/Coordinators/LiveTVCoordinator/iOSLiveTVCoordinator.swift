//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class LiveTVCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \LiveTVCoordinator.start)

    @Root
    var start = makeStart

    @Route(.push)
    var channels = makeChannels

    func makeChannels() -> ChannelLibraryView {
        ChannelLibraryView()
    }

    @ViewBuilder
    func makeStart() -> some View {
        ProgramsView()
    }
}
