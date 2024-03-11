//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A `View` that automatically generates a SwiftUI `Picker` if `Element` conforms to `CaseIterable`.
///
/// If `Element` is optional, an additional `none` value is added to select `nil` that can be customized
/// by `.noneStyle()`.
struct CaseIterablePicker<Element: CaseIterable & Displayable & Hashable>: View {

    enum NoneStyle: Displayable {

        case text
        case dash(Int)
        case custom(String)

        var displayTitle: String {
            switch self {
            case .text:
                return L10n.none
            case let .dash(length):
                assert(length >= 1, "Dash must have length of at least 1.")
                return String(repeating: "-", count: length)
            case let .custom(text):
                assert(text.isNotEmpty, "Custom text must have length of at least 1.")
                return text
            }
        }
    }

    @Binding
    private var selection: Element?

    private let title: String
    private let hasNone: Bool
    private var noneStyle: NoneStyle

    var body: some View {
        Picker(title, selection: $selection) {

            if hasNone {
                Text(noneStyle.displayTitle)
                    .tag(nil as Element?)
            }

            ForEach(Element.allCases.asArray, id: \.hashValue) {
                Text($0.displayTitle)
                    .tag($0 as Element?)
            }
        }
    }
}

extension CaseIterablePicker {

    init(title: String, selection: Binding<Element?>) {
        self.init(
            selection: selection,
            title: title,
            hasNone: true,
            noneStyle: .text
        )
    }

    init(title: String, selection: Binding<Element>) {
        self.title = title

        let binding = Binding<Element?> {
            selection.wrappedValue
        } set: { newValue, _ in
            precondition(newValue != nil, "Should not have nil new value with non-optional binding")
            selection.wrappedValue = newValue!
        }

        self._selection = binding

        self.hasNone = false
        self.noneStyle = .text
    }

    func noneStyle(_ newStyle: NoneStyle) -> Self {
        copy(modifying: \.noneStyle, with: newStyle)
    }
}
