//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class LiveTVTabCoordinator: TabCoordinatable {

    var child = TabChild(startingItems: [
        \LiveTVTabCoordinator.programs,
        \LiveTVTabCoordinator.channels,
        \LiveTVTabCoordinator.home,
    ])

    @Route(tabItem: makeProgramsTab)
    var programs = makePrograms
    @Route(tabItem: makeChannelsTab)
    var channels = makeChannels
    @Route(tabItem: makeHomeTab)
    var home = makeHome

    func makePrograms() -> NavigationViewCoordinator<LiveTVProgramsCoordinator> {
        NavigationViewCoordinator(LiveTVProgramsCoordinator())
    }

    @ViewBuilder
    func makeProgramsTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "tv")
            L10n.programs.text
        }
    }

    func makeChannels() -> NavigationViewCoordinator<LiveTVChannelsCoordinator> {
        NavigationViewCoordinator(LiveTVChannelsCoordinator())
    }

    @ViewBuilder
    func makeChannelsTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "square.grid.3x3")
            L10n.channels.text
        }
    }

    func makeHome() -> LiveTVHomeView {
        LiveTVHomeView()
    }

    @ViewBuilder
    func makeHomeTab(isActive: Bool) -> some View {
        HStack {
            Image(systemName: "house")
            L10n.home.text
        }
    }
}
