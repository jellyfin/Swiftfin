//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

/// https://developer.apple.com/design/human-interface-guidelines/ornaments
struct OrnamentButton: View {

    // MARK: - Accent Color

    @Default(.accentColor)
    private var accentColor

    // MARK: - Environment Objects

    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isSelected)
    private var isSelected

    // MARK: - Required Configuration

    private let systemName: String

    // MARK: - Optional Configuration

    private let size: CGFloat
    private let action: () -> Void

    init(
        systemName: String,
        size: CGFloat = UIFont.preferredFont(forTextStyle: .headline).pointSize * 1.5,
        action: @escaping () -> Void = {}
    ) {
        self.systemName = systemName
        self.size = size
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .backport
                .fontWeight(.semibold)
                .imageScale(.small)
                .foregroundStyle(
                    isSelected ? Color.systemBackground : accentColor
                )
                .frame(width: size, height: size)
                .background(backgroundView)
                .overlay(
                    Circle()
                        .fill(.black.opacity(isEnabled ? 0.0 : 0.5))
                )
                .contentShape(Circle())
                .posterShadow()
        }
        .buttonStyle(.borderless)
    }

    // MARK: - Background View

    @ViewBuilder
    private var backgroundView: some View {
        if isSelected {
            Circle()
                .fill(accentColor)
        } else {
            Circle()
                .fill(.regularMaterial)
        }
    }
}
