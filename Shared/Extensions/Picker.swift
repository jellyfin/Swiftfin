//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct _OptionalCaseIterablePickerContent<Element: CaseIterable & Displayable & Hashable>: View {

    let noneStyle: NoneStyle

    var body: some View {
        Text(noneStyle.displayTitle)
            .tag(nil as Element?)

        ForEach(Array(Element.allCases), id: \.hashValue) {
            Text($0.displayTitle)
                .tag($0 as Element?)
        }
    }
}

struct _CaseIterablePickerContent<Element: CaseIterable & Displayable & Hashable>: View {

    var body: some View {
        ForEach(Array(Element.allCases), id: \.hashValue) {
            Text($0.displayTitle)
                .tag($0 as Element)
        }
    }
}

struct _SupportedCaseIterablePickerContent<Element: SupportedCaseIterable & Displayable & Hashable>: View {

    let onlySupported: Bool

    private var elements: [Element] {
        onlySupported ? Array(Element.supportedCases) : Array(Element.allCases)
    }

    var body: some View {
        ForEach(elements, id: \.hashValue) {
            Text($0.displayTitle)
                .tag($0 as Element)
        }
    }
}

struct _OptionalSourcesPickerContent<Element: Identifiable & Displayable & Hashable, Data: RandomAccessCollection>: View
where Data.Element == Element {

    let sources: Data
    let noneStyle: NoneStyle?

    var body: some View {
        if let noneStyle {
            Text(noneStyle.displayTitle)
                .tag(nil as Element?)
        }

        ForEach(sources) { element in
            Text(element.displayTitle)
                .tag(element as Element?)
        }
    }
}

extension Picker where Label == Text {

    init<E: CaseIterable & Displayable & Hashable>(
        _ title: String,
        selection: Binding<E?>,
        noneStyle: NoneStyle = .text
    ) where SelectionValue == E?, Content == _OptionalCaseIterablePickerContent<E> {
        self.init(title, selection: selection) {
            _OptionalCaseIterablePickerContent<E>(noneStyle: noneStyle)
        }
    }

    init(
        _ title: String,
        selection: Binding<SelectionValue>
    ) where SelectionValue: CaseIterable & Displayable & Hashable, Content == _CaseIterablePickerContent<SelectionValue> {
        self.init(title, selection: selection) {
            _CaseIterablePickerContent<SelectionValue>()
        }
    }

    init(
        _ title: String,
        selection: Binding<SelectionValue>,
        onlySupported: Bool = false
    ) where SelectionValue: Displayable & Hashable & SupportedCaseIterable, Content == _SupportedCaseIterablePickerContent<SelectionValue> {
        self.init(title, selection: selection) {
            _SupportedCaseIterablePickerContent<SelectionValue>(onlySupported: onlySupported)
        }
    }

    init<E: Displayable & Hashable & Identifiable, Data: RandomAccessCollection>(
        _ title: String,
        sources: Data,
        selection: Binding<E?>,
        noneStyle: NoneStyle? = .text
    ) where SelectionValue == E?, Content == _OptionalSourcesPickerContent<E, Data>, Data.Element == E {
        self.init(title, selection: selection) {
            _OptionalSourcesPickerContent(sources: sources, noneStyle: noneStyle)
        }
    }
}
