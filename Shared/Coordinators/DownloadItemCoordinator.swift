//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import Stinsen
import SwiftUI

final class DownloadItemCoordinator: NavigationCoordinatable {
    
    let stack = NavigationStack(initial: \DownloadItemCoordinator.start)
    
    @Root
    var start = makeStart
    
    let viewModel: ItemViewModel
    
    init(viewModel: ItemViewModel) {
        self.viewModel = viewModel
    }
    
    @ViewBuilder
    func makeStart() -> some View {
        let viewModel = DownloadItemViewModel(itemViewModel: viewModel)
        DownloadItemView(viewModel: viewModel)
    }
}
