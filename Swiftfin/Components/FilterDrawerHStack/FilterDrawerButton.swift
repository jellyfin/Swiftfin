//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension FilterDrawerHStack {

    struct FilterDrawerButton: View {

        @Default(.accentColor)
        private var accentColor

        private let systemName: String?
        private let title: String
        private let activated: Bool
        private var onSelect: () -> Void

        private init(
            systemName: String?,
            title: String,
            activated: Bool,
            onSelect: @escaping () -> Void
        ) {
            self.systemName = systemName
            self.title = title
            self.activated = activated
            self.onSelect = onSelect
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                HStack(spacing: 2) {
                    Group {
                        if let systemName = systemName {
                            Image(systemName: systemName)
                        } else {
                            Text(title)
                        }
                    }
                    .font(.footnote.weight(.semibold))

                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .foregroundColor(activated ? accentColor : Color(UIColor.secondarySystemFill))
                        .opacity(0.5)
                }
                .overlay {
                    Capsule()
                        .stroke(activated ? accentColor : Color(UIColor.secondarySystemFill), lineWidth: 1)
                }
            }
        }
    }
}

extension FilterDrawerHStack.FilterDrawerButton {
    init(title: String, activated: Bool) {
        self.init(
            systemName: nil,
            title: title,
            activated: activated,
            onSelect: {}
        )
    }

    init(systemName: String, activated: Bool) {
        self.init(
            systemName: systemName,
            title: "",
            activated: activated,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
