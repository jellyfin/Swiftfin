//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct PrimaryButton: View {

    @Default(.accentColor)
    private var accentColor

    private let title: String
    private let action: () -> Void

    init(title: String, _ action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Rectangle()
                    .foregroundColor(accentColor)
                    .frame(maxWidth: 400)
                    .frame(height: 50)
                    .cornerRadius(10)

                Text(title)
                    .foregroundColor(accentColor.overlayColor)
                    .bold()
            }
        }
    }
}
