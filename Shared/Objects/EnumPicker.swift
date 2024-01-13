//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EnumPicker<EnumType: CaseIterable & Displayable & Hashable>: View {

    enum NoneStyle: Displayable {

        case text
        case dash(Int)
        case custom(String)

        var displayTitle: String {
            switch self {
            case .text:
                return L10n.none
            case let .dash(length):
                precondition(length >= 1, "Dash must have length of at least 1.")
                return String(repeating: "-", count: length)
            case let .custom(text):
                precondition(!text.isEmpty, "Custom text must have length of at least 1.")
                return text
            }
        }
    }

    @Binding
    private var selection: EnumType?

    private let title: String
    private let hasNil: Bool
    private var noneStyle: NoneStyle

    var body: some View {
        Picker(title, selection: $selection) {

            if hasNil {
                Text(noneStyle.displayTitle)
                    .tag(nil as EnumType?)
            }

            ForEach(EnumType.allCases.asArray, id: \.hashValue) {
                Text($0.displayTitle)
                    .tag($0 as EnumType?)
            }
        }
    }
}

extension EnumPicker {

    init(title: String, selection: Binding<EnumType?>) {
        self.title = title
        self._selection = selection
        self.hasNil = true
        self.noneStyle = .text
    }

    init(title: String, selection: Binding<EnumType>) {
        self.title = title

        let binding = Binding<EnumType?> {
            selection.wrappedValue
        } set: { newValue, _ in
            assert(newValue != nil, "Should not have nil new value with non-optional binding")
            selection.wrappedValue = newValue!
        }

        self._selection = binding

        self.hasNil = false
        self.noneStyle = .text
    }

    func noneStyle(_ newStyle: NoneStyle) -> Self {
        copy(modifying: \.noneStyle, with: newStyle)
    }
}
