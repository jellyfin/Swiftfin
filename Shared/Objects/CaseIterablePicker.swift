//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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

    @ViewBuilder
    private var label: (Element) -> any View

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
                label($0)
                    .eraseToAnyView()
                    .tag($0 as Element?)
            }
        }
    }
}

// MARK: Text

extension CaseIterablePicker {

    init(_ title: String, selection: Binding<Element?>) {
        self.init(
            selection: selection,
            label: { Text($0.displayTitle) },
            title: title,
            hasNone: true,
            noneStyle: .text
        )
    }

    init(_ title: String, selection: Binding<Element>) {
        let binding = Binding<Element?> {
            selection.wrappedValue
        } set: { newValue, _ in
            precondition(newValue != nil, "Should not have nil new value with non-optional binding")
            selection.wrappedValue = newValue!
        }

        self.init(
            selection: binding,
            label: { Text($0.displayTitle) },
            title: title,
            hasNone: false,
            noneStyle: .text
        )
    }

    func noneStyle(_ newStyle: NoneStyle) -> Self {
        copy(modifying: \.noneStyle, with: newStyle)
    }
}

// MARK: Label

// TODO: I didn't entirely like the forced label design that this
//       uses, decide whether to actually keep

// extension CaseIterablePicker where Element: SystemImageable {
//
//    init(title: String, selection: Binding<Element?>) {
//        self.init(
//            selection: selection,
//            label: { Label($0.displayTitle, systemImage: $0.systemImage) },
//            title: title,
//            hasNone: true,
//            noneStyle: .text
//        )
//    }
//
//    init(title: String, selection: Binding<Element>) {
//        let binding = Binding<Element?> {
//            selection.wrappedValue
//        } set: { newValue, _ in
//            precondition(newValue != nil, "Should not have nil new value with non-optional binding")
//            selection.wrappedValue = newValue!
//        }
//
//        self.init(
//            selection: binding,
//            label: { Label($0.displayTitle, systemImage: $0.systemImage) },
//            title: title,
//            hasNone: false,
//            noneStyle: .text
//        )
//    }
// }
