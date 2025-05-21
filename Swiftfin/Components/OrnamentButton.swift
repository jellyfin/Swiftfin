//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct OrnamentButton<Content: View>: View {

    // MARK: - Accent Color

    @Default(.accentColor)
    private var accentColor

    // MARK: - Environment

    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isSelected)
    private var isSelected

    // MARK: - Configuration

    private let title: String
    private let systemName: String
    private let size: CGFloat
    private let onSelect: () -> Void
    private let content: () -> Content

    // MARK: - Body

    var body: some View {
        Group {
            if Content.self == EmptyView.self {
                Button(action: onSelect) {
                    ornamentIcon
                }
                .buttonStyle(.borderless)
            } else {
                Menu(content: content) {
                    ornamentIcon
                }
                .menuStyle(.borderlessButton)
            }
        }
        .labelStyle(.iconOnly)
        .accessibilityLabel(title)
        .symbolRenderingMode(.palette)
    }

    // MARK: - Ornament Icon

    private var ornamentIcon: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundStyle(foregroundStyle)
            .frame(width: size, height: size)
            .background(
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                    Circle()
                        .fill(backgroundFill)
                }
            )
            .contentShape(Circle())
    }

    // MARK: - Background Color Fill

    private var backgroundFill: Color {
        if !isEnabled {
            Color.secondary
        } else if isSelected {
            accentColor
        } else {
            Color(UIColor.secondarySystemFill)
                .opacity(0.5)
        }
    }

    // MARK: - Foreground Color

    private var foregroundStyle: Color {
        if !isEnabled {
            Color.primary
        } else if isSelected {
            Color.systemBackground
        } else {
            accentColor
        }
    }
}

extension OrnamentButton {

    // MARK: - Initialize as Button

    init(
        _ title: String,
        systemName: String,
        size: CGFloat = UIFont.preferredFont(forTextStyle: .headline).pointSize * 1.5,
        onSelect: @escaping () -> Void
    ) where Content == EmptyView {
        self.title = title
        self.systemName = systemName
        self.size = size
        self.onSelect = onSelect
        self.content = { EmptyView() }
    }

    // MARK: - Initialize as Menu

    init(
        _ title: String,
        systemName: String,
        size: CGFloat = UIFont.preferredFont(forTextStyle: .headline).pointSize * 1.5,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemName = systemName
        self.size = size
        self.onSelect = {}
        self.content = content
    }
}
