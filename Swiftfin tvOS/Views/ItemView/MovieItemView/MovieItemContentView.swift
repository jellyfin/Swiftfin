//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension MovieItemView {

    struct ContentView: View {

        @ObservedObject
        var viewModel: MovieItemViewModel
        @FocusState
        var isFocused: Bool

        var body: some View {
            HStack {
                VStack {
                    ForEach(0 ..< 10) { _ in
                        ItemView.PlayButton(viewModel: viewModel)
                    }
                }

                Spacer()
            }
        }
    }
}
