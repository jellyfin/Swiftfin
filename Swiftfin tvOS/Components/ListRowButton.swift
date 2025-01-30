//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ListRowButton: View {

    let title: String
    let role: ButtonRole?
    let action: () -> Void

    init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(secondaryStyle)

                Text(title)
                    .foregroundStyle(primaryStyle)
                    .font(.body.weight(.bold))
            }
        }
        .buttonStyle(.card)
        .frame(height: 75)
    }

    // MARK: - Styles

    private var primaryStyle: some ShapeStyle {
        if role == .destructive {
            return AnyShapeStyle(Color.red)
        } else {
            return AnyShapeStyle(.primary)
        }
    }

    private var secondaryStyle: some ShapeStyle {
        if role == .destructive {
            return AnyShapeStyle(Color.red.opacity(0.2))
        } else {
            return AnyShapeStyle(.secondary)
        }
    }
}
