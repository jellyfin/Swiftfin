//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension FilterDrawer {

    struct FilterDrawerButton: View {

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
        private var onSelect: () -> Void

        // MARK: - Collapsing Variables

        private let expandedWidth: CGFloat
        private let collapsedWidth: CGFloat = 75

        // MARK: - Position Detection Variables

        @State
        private var screenPosition: CGFloat = 0
        @State
        private var screenWidth: CGFloat = UIScreen.main.bounds.width

        // TODO: Feels expensive to calculate...
        private var expansionDirection: Alignment {
            screenPosition < screenWidth / 2 ? .trailing : .leading
        }

        // MARK: - Initializer

        init(
            systemName: String?,
            title: String,
            expandedWidth: CGFloat,
            onSelect: @escaping () -> Void
        ) {
            self.systemName = systemName
            self.title = title
            self.expandedWidth = expandedWidth
            self.onSelect = onSelect
        }

        // MARK: - Body

        var body: some View {
            Button {
                onSelect()
            } label: {
                // TODO: Is there a cleaner way to get this switch directions?
                HStack(spacing: 8) {
                    if expansionDirection == .trailing {
                        if let systemName = systemName {
                            Image(systemName: systemName)
                                .frame(width: collapsedWidth, alignment: .center)
                                .focusable(false)
                        }
                        if isFocused {
                            Text(title)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                            Spacer(minLength: 0)
                        }
                    } else {
                        if isFocused {
                            Spacer(minLength: 0)
                            Text(title)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                        if let systemName = systemName {
                            Image(systemName: systemName)
                                .frame(width: collapsedWidth, alignment: .center)
                                .focusable(false)
                        }
                    }
                }
                .font(.footnote.weight(.semibold))
                .foregroundColor(isFocused ? .primary : .secondary)
                .frame(
                    width: isFocused ? expandedWidth : collapsedWidth,
                    height: collapsedWidth,
                    alignment: expansionDirection == .trailing ? .leading : .trailing
                )
                .background {
                    Capsule()
                        .foregroundColor(isSelected ? accentColor : Color.secondarySystemFill)
                        .brightness(isFocused ? 0.25 : 0)
                        .opacity(0.5)
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? accentColor : Color.secondarySystemFill, lineWidth: 1)
                        .brightness(isFocused ? 0.25 : 0)
                }
                .animation(.easeInOut(duration: 0.25), value: isFocused)
            }
            .frame(width: collapsedWidth, height: collapsedWidth, alignment: expansionDirection == .trailing ? .leading : .trailing)
            .padding(0)
            .buttonStyle(.borderless)
            .focused($isFocused)
            .background(
                GeometryReader { geometry -> Color in
                    let globalFrame = geometry.frame(in: .global)

                    DispatchQueue.main.async {
                        screenPosition = globalFrame.midX
                        screenWidth = UIScreen.main.bounds.width
                    }

                    return Color.clear
                }
            )
        }
    }
}

extension FilterDrawer.FilterDrawerButton {
    init(systemName: String, title: String) {
        self.init(
            systemName: systemName,
            title: title,
            expandedWidth: 200,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
