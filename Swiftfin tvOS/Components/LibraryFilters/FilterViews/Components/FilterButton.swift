//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct FilterButton: View {

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Environment Variables

    @Environment(\.isSelected)
    private var isSelected

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool

    // MARK: - Button Variables

    private let systemName: String?
    private let title: String
    private let role: ButtonRole?
    private var onSelect: () -> Void

    // MARK: - Button Widths

    private let collapsedWidth: CGFloat = 75

    private var expandedWidth: CGFloat {
        textWidth(for: title) + 20 + collapsedWidth
    }

    // MARK: - Button Styles

    private var buttonColor: Color {
        isSelected ? ((role == .destructive && isFocused) ? .red : accentColor) : Color.secondarySystemFill
    }

    private var textColor: Color {
        isFocused ? ((role == .destructive) ? Color.red.opacity(0.2) : .black) : .primary
    }

    // MARK: - Initializer

    init(
        systemName: String?,
        title: String,
        role: ButtonRole?,
        onSelect: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.title = title
        self.role = role
        self.onSelect = onSelect
    }

    // MARK: - Text Width

    private func textWidth(for text: String) -> CGFloat {
        let textSize = String().height(
            withConstrainedWidth: CGFloat.greatestFiniteMagnitude,
            font: UIFont.preferredFont(
                forTextStyle: .footnote
            )
        )
        let font = UIFont.systemFont(ofSize: textSize, weight: .semibold)
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width
    }

    // MARK: - Body

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 10) {
                if let systemName = systemName {
                    Image(systemName: systemName)
                        .hoverEffectDisabled()
                        .focusEffectDisabled()
                        .foregroundColor(textColor)
                        .frame(width: collapsedWidth, alignment: .center)
                        .focusable(false)
                }
                if isFocused {
                    Text(title)
                        .foregroundColor(textColor)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    Spacer(minLength: 0)
                }
            }
            .font(.footnote.weight(.semibold))
            .frame(
                width: isFocused ? expandedWidth : collapsedWidth,
                height: collapsedWidth,
                alignment: .leading
            )
            .background {
                Capsule()
                    .foregroundColor(buttonColor)
                    .brightness(isFocused ? 0.25 : 0)
                    .opacity(isFocused ? 1 : 0.5)
            }
            .overlay {
                Capsule()
                    .stroke(buttonColor, lineWidth: 1)
                    .brightness(isFocused ? 0.25 : 0)
            }
            .animation(.easeInOut(duration: 0.25), value: isFocused)
        }
        .frame(width: collapsedWidth, height: collapsedWidth, alignment: .leading)
        .padding(0)
        .buttonStyle(.borderless)
        .focused($isFocused)
    }
}

extension FilterButton {
    init(systemName: String, title: String, role: ButtonRole? = nil) {
        self.init(
            systemName: systemName,
            title: title,
            role: role,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
