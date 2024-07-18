//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: come up with better name along with `ListRow`

// Meant to be used within `List` or `Form`
struct ListRowButton: View {

    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title) {
            action()
        }
        .font(.body.weight(.bold))
        .buttonStyle(ListRowButtonStyle())
        .listRowInsets(.init(.zero))
    }
}

private struct ListRowButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.secondary)

            configuration.label
                .foregroundStyle(.primary)
        }
        .opacity(configuration.isPressed ? 0.75 : 1)
        .frame(maxWidth: .infinity)
        .listRowInsets(.zero)
    }
}
