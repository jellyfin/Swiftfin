//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SplitFormWindowView: View {

    private var contentView: () -> any View
    private var descriptionView: () -> any View

    var body: some View {
        HStack {

            descriptionView()
                .eraseToAnyView()
                .frame(maxWidth: .infinity)

            Form {
                contentView()
                    .eraseToAnyView()
            }
            .padding(.top)
            .scrollClipDisabled()
        }
    }
}

extension SplitFormWindowView {

    init() {
        self.init(
            contentView: { EmptyView() },
            descriptionView: { Color.clear }
        )
    }

    func contentView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.contentView, with: content)
    }

    func descriptionView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.descriptionView, with: content)
    }
}
