//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
        Button(title, action: action)
            .font(.body.weight(.bold))
            .buttonStyle(ListRowButtonStyle())
            .listRowInsets(.init(.zero))
    }
}

// TODO: implement `role`
private struct ListRowButtonStyle: ButtonStyle {

    @Environment(\.isEnabled)
    private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Rectangle()
                .foregroundStyle(isEnabled ? AnyShapeStyle(HierarchicalShapeStyle.secondary) : AnyShapeStyle(Color.gray))

            configuration.label
                .foregroundStyle(.primary)
        }
        .opacity(configuration.isPressed ? 0.75 : 1)
        .frame(maxWidth: .infinity)
        .listRowInsets(.zero)
    }
}
