//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension NameIDPair: Displayable {

    var displayTitle: String {
        name ?? .emptyDash
    }
}

// TODO: strong type studios and implement as `LibraryParent`
extension NameIDPair: LibraryParent {

    var libraryType: BaseItemKind? {
        .studio
    }
}

extension NameIDPair: LibraryElement {

    func makeBody(
        libraryStyle: LibraryStyle,
        action: (() -> Void)?
    ) -> some View {
        NameIDPairLibraryListElement(
            element: self,
            action: action
        )
    }
}

private struct NameIDPairLibraryListElement: View {

    @Environment(\.isEditing)
    private var isEditing
    @Environment(\.isSelected)
    private var isSelected

    let element: NameIDPair
    var action: (() -> Void)?

    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(element.displayTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(
                        isEditing ? (isSelected ? .primary : .secondary) : .primary
                    )

                if isEditing {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }
            }
        }
    }
}
