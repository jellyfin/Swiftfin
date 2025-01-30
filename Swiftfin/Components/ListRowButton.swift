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

    private let title: String
    private let role: ButtonRole?
    private let action: () -> Void

    init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(title, role: role, action: action)
            .buttonStyle(ListRowButtonStyle())
            .listRowInsets(.zero)
    }
}

private struct ListRowButtonStyle: ButtonStyle {

    @Environment(\.isEnabled)
    private var isEnabled

    private func primaryStyle(configuration: Configuration) -> some ShapeStyle {
        if configuration.role == .destructive || configuration.role == .cancel {
            return AnyShapeStyle(Color.red)
        } else {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        }
    }

    private func secondaryStyle(configuration: Configuration) -> some ShapeStyle {
        if configuration.role == .destructive {
            return AnyShapeStyle(Color.red.opacity(0.2))
        } else {
            return isEnabled ? AnyShapeStyle(HierarchicalShapeStyle.secondary) : AnyShapeStyle(Color.gray)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Rectangle()
                .fill(secondaryStyle(configuration: configuration))

            configuration.label
                .foregroundStyle(primaryStyle(configuration: configuration))
        }
        .opacity(configuration.isPressed ? 0.75 : 1)
        .font(.body.weight(.bold))
    }
}
