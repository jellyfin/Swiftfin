//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FilterDrawerButton: View {
    
    private let title: String
    private let activated: Bool
    private var onSelect: () -> Void
    
    private init(title: String,
                 activated: Bool,
                 onSelect: @escaping () -> Void) {
        self.title = title
        self.activated = activated
        self.onSelect = onSelect
    }

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule()
                    .foregroundColor(activated ? .jellyfinPurple : Color(UIColor.secondarySystemFill))
                    .opacity(0.5)
            }
            .overlay(
                Capsule()
                    .stroke(activated ? .purple : Color(UIColor.secondarySystemFill), lineWidth: 1)
            )
        }
    }
}

extension FilterDrawerButton {
    init(title: String, activated: Bool) {
        self.init(
            title: title,
            activated: activated,
            onSelect: { })
    }
    
    func onSelect(_ action: @escaping () -> Void) -> Self {
        var copy = self
        copy.onSelect = action
        return copy
    }
}
