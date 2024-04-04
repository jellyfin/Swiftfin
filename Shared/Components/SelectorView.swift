//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Label generic not really necessary if just restricting to `Text`
//       - go back to `any View` implementation instead

enum SelectorType {
    case single
    case multi
}

struct SelectorView<Element: Displayable & Hashable, Label: View>: View {

    @Environment(\.accentColor)
    private var accentColor

    @Binding
    private var selection: Set<Element>

    private let sources: [Element]
    private var label: (Element) -> Label
    private let type: SelectorType

    var body: some View {
        List(sources, id: \.hashValue) { element in
            Button {
                switch type {
                case .single:
                    handleSingleSelect(with: element)
                case .multi:
                    handleMultiSelect(with: element)
                }
            } label: {
                HStack {
                    label(element)

                    Spacer()

                    if selection.contains(element) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                            .paletteOverlayRendering()
                    }
                }
            }
        }
    }

    private func handleSingleSelect(with element: Element) {
        selection = [element]
    }

    private func handleMultiSelect(with element: Element) {
        if selection.contains(element) {
            selection.remove(element)
        } else {
            selection.insert(element)
        }
    }
}

extension SelectorView where Label == Text {

    init(selection: Binding<[Element]>, sources: [Element], type: SelectorType) {

        let selectionBinding = Binding {
            Set(selection.wrappedValue)
        } set: { newValue in
            selection.wrappedValue = sources.intersection(newValue)
        }

        self.init(
            selection: selectionBinding,
            sources: sources,
            label: { Text($0.displayTitle).foregroundColor(.primary) },
            type: type
        )
    }

    init(selection: Binding<Element>, sources: [Element]) {

        let selectionBinding = Binding {
            Set([selection.wrappedValue])
        } set: { newValue in
            selection.wrappedValue = newValue.first!
        }

        self.init(
            selection: selectionBinding,
            sources: sources,
            label: { Text($0.displayTitle).foregroundColor(.primary) },
            type: .single
        )
    }
}

extension SelectorView {

    func label(@ViewBuilder _ content: @escaping (Element) -> Label) -> Self {
        copy(modifying: \.label, with: content)
    }
}
