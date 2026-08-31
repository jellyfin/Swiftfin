//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension EPGDateBar {

    struct DatePill: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected

        @FocusState
        private var isFocused: Bool

        private let title: String
        private let action: () -> Void

        init(date: Date, action: @escaping () -> Void) {
            self.title = date.formatted(.dateTime.weekday(.abbreviated).day())
            self.action = action
        }

        private var tint: Color? {
            if isFocused {
                .white
            } else if isSelected {
                accentColor.opacity(0.5)
            } else {
                nil
            }
        }

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backport
                    .glassEffect(
                        .regular.selection(
                            tint: tint,
                            foregroundColor: isFocused ? .black : .primary
                        )
                        .interactive(),
                        in: .capsule
                    )
            }
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.06 : 1)
            .animation(.easeInOut(duration: 0.1), value: isFocused)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
}
