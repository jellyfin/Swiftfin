//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct PrimaryButton: View {

    @Default(.accentColor)
    private var accentColor

    private let title: String
    private let role: ButtonRole?
    private var onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            ZStack {
                Rectangle()
                    .foregroundColor(role == .destructive ? Color.red.opacity(0.2) : accentColor)
                    .frame(maxWidth: 400)
                    .frame(height: 50)
                    .cornerRadius(10)

                Text(title)
                    .fontWeight(.bold)
                    .foregroundColor(role == .destructive ? Color.red : accentColor.overlayColor)
            }
        }
    }
}

extension PrimaryButton {

    init(title: String, role: ButtonRole? = nil) {
        self.init(
            title: title,
            role: role,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
