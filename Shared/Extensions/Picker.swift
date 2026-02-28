//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@ViewBuilder
func Picker<Element: CaseIterable & Displayable & Hashable>(
    _ title: String,
    selection: Binding<Element?>,
    noneStyle: Picker<EmptyView, Element, EmptyView>.NoneStyle = .text
) -> some View {
    SwiftUI.Picker(title, selection: selection) {
        Text(noneStyle.displayTitle)
            .tag(nil as Element?)

        ForEach(Element.allCases.asArray, id: \.hashValue) {
            Text($0.displayTitle)
                .tag($0 as Element?)
        }
    }
}

@ViewBuilder
func Picker<Element: CaseIterable & Displayable & Hashable>(
    _ title: String,
    selection: Binding<Element>
) -> some View {
    SwiftUI.Picker(title, selection: selection) {
        ForEach(Element.allCases.asArray, id: \.hashValue) {
            Text($0.displayTitle)
                .tag($0 as Element)
        }
    }
}

@ViewBuilder
func Picker<Element: SupportedCaseIterable & Displayable & Hashable>(
    _ title: String,
    selection: Binding<Element>,
    onlySupported: Bool = false
) -> some View {

    let elements = onlySupported ? Element.supportedCases.asArray : Element.allCases.asArray

    SwiftUI.Picker(title, selection: selection) {
        ForEach(elements, id: \.hashValue) {
            Text($0.displayTitle)
                .tag($0 as Element)
        }
    }
}

@ViewBuilder
func Picker<Element: Identifiable & Displayable & Hashable, Data: RandomAccessCollection>(
    _ title: String,
    sources: Data,
    selection: Binding<Element?>,
    noneStyle: Picker<EmptyView, Element, EmptyView>.NoneStyle = .text
) -> some View where Data.Element == Element {
    SwiftUI.Picker(title, selection: selection) {
        Text(noneStyle.displayTitle)
            .tag(nil as Element?)

        ForEach(sources) { element in
            Text(element.displayTitle)
                .tag(element as Element?)
        }
    }
}

extension Picker {

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
}
