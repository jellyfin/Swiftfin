//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct NavigationBarBrandingModifier: ViewModifier {

    var isLoading: Bool?

    func body(content: Self.Content) -> some View {
        VStack {
            VStack(alignment: .trailing) {
                if let loading = isLoading, loading == true {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .overlay {
                Image(.jellyfinBlobBlue)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .edgePadding()
            }
            .padding(.bottom)

            content

            Spacer()
        }
    }
}
