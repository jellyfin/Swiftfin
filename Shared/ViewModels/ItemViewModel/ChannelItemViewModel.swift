//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
final class ChannelItemViewModel: LiveContentViewModel {

    let programs: PagingLibraryViewModel<ChannelProgramsLibrary>

    @MainActor
    override init(item: BaseItemDto) {
        self.programs = .init(library: ChannelProgramsLibrary(channel: item))
        super.init(item: item)
    }

    override func respond(to action: ItemViewModel.Action) -> ItemViewModel.State {
        switch action {
        case .backgroundRefresh, .refresh:
            programs.refresh()
        default: ()
        }

        return super.respond(to: action)
    }
}
