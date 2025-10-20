//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// typealias SupportedCaseIterablePicker = CaseIterablePicker<SupportedCaseIterable

/// A `View` that automatically generates a SwiftUI `Picker` if `Element` conforms to `CaseIterable`.
///
/// If `Element` is optional, an additional `none` value is added to select `nil` that can be customized
/// by `.noneStyle()`.
struct CaseIterablePicker<Element: CaseIterable & Displayable & Hashable, Label: View>: View {

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

    private var elements: [Element]
    private let label: (Element) -> Label
    private var noneStyle: NoneStyle?
    private let selection: Binding<Element?>
    private let title: String

    var body: some View {
        Picker(title, selection: selection) {

            if let noneStyle {
                Text(noneStyle.displayTitle)
                    .tag(nil as Element?)
            }

            ForEach(elements, id: \.hashValue) {
                label($0)
                    .tag($0 as Element?)
            }
        }
    }
}

// MARK: Text

extension CaseIterablePicker where Label == Text {

    init(_ title: String, selection: Binding<Element?>) {
        self.init(
            elements: Element.allCases.asArray,
            label: { Text($0.displayTitle) },
            noneStyle: .text,
            selection: selection,
            title: title
        )
    }

    init(_ title: String, selection: Binding<Element>) {
        let newSelection = Binding<Element?> {
            selection.wrappedValue
        } set: { newValue, _ in
            precondition(newValue != nil, "Should not have nil new value with non-optional binding")
            selection.wrappedValue = newValue!
        }

        self.init(
            elements: Element.allCases.asArray,
            label: { Text($0.displayTitle) },
            noneStyle: nil,
            selection: newSelection,
            title: title
        )
    }

    func noneStyle(_ newStyle: NoneStyle) -> Self {
        copy(modifying: \.noneStyle, with: newStyle)
    }
}

extension CaseIterablePicker where Element: SupportedCaseIterable, Label == Text {

    // TODO: only used for poster settings, remove after conformance is removed
    //       - or, keep and be used for for options that have an "enabled/none" case
    //         when they should be a toggle + picker
    func onlySupportedCases(_ value: Bool) -> Self {
        if value {
            return copy(modifying: \.elements, with: Element.supportedCases.asArray)
        } else {
            return self
        }
    }
}
