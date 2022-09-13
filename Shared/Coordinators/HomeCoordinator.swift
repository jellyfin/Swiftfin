//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Stinsen
import SwiftUI

final class HomeCoordinator: NavigationCoordinatable {

    let stack = NavigationStack(initial: \HomeCoordinator.start)

    @Root
    var start = makeStart
    @Route(.modal)
    var settings = makeSettings

    #if os(tvOS)
    @Route(.modal)
    var item = makeItem
    @Route(.modal)
    var basicLibrary = makeBasicLibrary
    @Route(.modal)
    var library = makeLibrary
    #else
    @Route(.push)
    var item = makeItem
    @Route(.push)
    var basicLibrary = makeBasicLibrary
    @Route(.push)
    var library = makeLibrary
    #endif

    func makeSettings() -> NavigationViewCoordinator<SettingsCoordinator> {
        NavigationViewCoordinator(SettingsCoordinator())
    }

    #if os(tvOS)
    func makeItem(item: BaseItemDto) -> NavigationViewCoordinator<ItemCoordinator> {
        NavigationViewCoordinator(ItemCoordinator(item: item))
    }

    func makeBasicLibrary(parameters: BasicLibraryCoordinator.Parameters) -> NavigationViewCoordinator<BasicLibraryCoordinator> {
        NavigationViewCoordinator(BasicLibraryCoordinator(parameters: parameters))
    }

    func makeLibrary(parameters: LibraryCoordinator.Parameters) -> NavigationViewCoordinator<LibraryCoordinator> {
        NavigationViewCoordinator(LibraryCoordinator(parameters: parameters))
    }
    #else
    func makeItem(item: BaseItemDto) -> ItemCoordinator {
        ItemCoordinator(item: item)
    }

    func makeBasicLibrary(parameters: BasicLibraryCoordinator.Parameters) -> BasicLibraryCoordinator {
        BasicLibraryCoordinator(parameters: parameters)
    }

    func makeLibrary(parameters: LibraryCoordinator.Parameters) -> LibraryCoordinator {
        LibraryCoordinator(parameters: parameters)
    }
    #endif

    @ViewBuilder
    func makeStart() -> some View {
        HomeView(viewModel: .init())
    }
}
