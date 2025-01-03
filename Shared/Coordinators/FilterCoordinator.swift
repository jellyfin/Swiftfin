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

final class FilterCoordinator: NavigationCoordinatable {

    struct Parameters {
        let type: ItemFilterType
        let viewModel: FilterViewModel
    }

    let stack = NavigationStack(initial: \FilterCoordinator.start)

    @Root
    var start = makeStart

    private let parameters: Parameters

    init(parameters: Parameters) {
        self.parameters = parameters
    }

    @ViewBuilder
    func makeStart() -> some View {
        #if os(tvOS)
        AssertionFailureView("Not implemented")
        #else
        FilterView(viewModel: parameters.viewModel, type: parameters.type)
        #endif
    }
}
