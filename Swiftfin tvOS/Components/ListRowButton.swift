//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ListRowButton: View {

    // MARK: - Environment

    @Environment(\.isEnabled)
    private var isEnabled

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool

    // MARK: - Button Variables

    let title: String
    let role: ButtonRole?
    let action: () -> Void

    // MARK: - Initializer

    init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(secondaryStyle)

                if !isEnabled {
                    Color.black.opacity(0.5)
                } else if isFocused {
                    Color.white.opacity(0.25)
                }

                Text(title)
                    .foregroundStyle(primaryStyle)
                    .font(.body.weight(.bold))
            }
        }
        .buttonStyle(.card)
        .frame(maxHeight: 75)
        .focused($isFocused)
    }

    // MARK: - Primary Style

    private var primaryStyle: some ShapeStyle {
        if role == .destructive {
            return AnyShapeStyle(Color.red)
        } else {
            return AnyShapeStyle(.primary)
        }
    }

    // MARK: - Secondary Style

    private var secondaryStyle: some ShapeStyle {
        if role == .destructive {
            return AnyShapeStyle(Color.red.opacity(0.2))
        } else {
            return AnyShapeStyle(.secondary)
        }
    }
}
