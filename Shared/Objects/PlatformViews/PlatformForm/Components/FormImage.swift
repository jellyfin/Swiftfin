//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FormImage: View {

    private let content: AnyView

    init(systemImage: String) {
        self.content = Image(systemName: systemImage)
            .resizable()
            .eraseToAnyView()
    }

    init(_ resource: ImageResource) {
        self.content = Image(resource)
            .resizable()
            .eraseToAnyView()
    }

    init<element: View>(@ViewBuilder content: () -> element) {
        self.content = content()
            .eraseToAnyView()
    }

    var body: some View {
        content
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
    }
}
