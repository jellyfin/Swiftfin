//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: removeContextMenu

typealias ContextMenuRegistry = TypeValueRegistry<(Any) -> (items: AnyView, preview: AnyView?)>

extension EnvironmentValues {

    @Entry
    var contextMenuRegistry: ContextMenuRegistry = .init()
}

enum EnvironmentContextMenu<Value> {

    struct Registar: ViewModifier {

        @Environment(\.contextMenuRegistry)
        private var contextMenuRegistry

        let menuContent: (Any) -> (items: AnyView, preview: AnyView?)

        init(menuContent: @escaping (Value) -> (menuContent: AnyView, preview: AnyView?)) {
            self.menuContent = { value in
                guard let value = value as? Value else {
                    return (AnyView(EmptyView()), nil)
                }
                let content = menuContent(value)
                return (AnyView(content.menuContent), AnyView(content.preview))
            }
        }

        func body(content: Content) -> some View {
            content
                .environment(\.contextMenuRegistry, contextMenuRegistry.insertOrReplace(menuContent, for: Value.self))
        }
    }

    struct Extractor: ViewModifier {

        @Environment(\.contextMenuRegistry)
        private var contextMenuRegistry

        private let value: Value
        private let previewOverride: ((Value) -> AnyView)?

        init(
            value: Value,
            preview: ((Value) -> AnyView)? = nil
        ) {
            self.value = value
            self.previewOverride = preview
        }

        func body(content: Content) -> some View {

            if let contextMenu = contextMenuRegistry.getvalue(for: Value.self)?(value) {
                if let previewOverride {
                    content
                        .contextMenu(
                            menuItems: { contextMenu.0 },
                            preview: { previewOverride(value) }
                        )
                } else if let preview = contextMenu.1 {
                    content
                        .contextMenu(
                            menuItems: { contextMenu.0 },
                            preview: { preview }
                        )
                } else {
                    content
                        .contextMenu(
                            menuItems: { contextMenu.0 }
                        )
                }
            } else {
                content
            }
        }
    }
}

extension View {

    /// Associates a context menu with a data type for use within
    /// subviews within the container.
    func contextMenu<V>(
        for type: V.Type,
        @ViewBuilder content: @escaping (V) -> some View
    ) -> some View {
        modifier(
            EnvironmentContextMenu.Registar(
                menuContent: {
                    let menuContent = content($0)
                    return (AnyView(menuContent), nil)
                }
            )
        )
    }

    /// Associates a context menu and preview with a data type for
    /// use within subviews within the container.
    func contextMenu<V>(
        for type: V.Type,
        @ViewBuilder content: @escaping (V) -> some View,
        @ViewBuilder preview: @escaping (V) -> some View
    ) -> some View {
        modifier(
            EnvironmentContextMenu.Registar(
                menuContent: {
                    let menuContent = content($0)
                    let previewContent = preview($0)
                    return (AnyView(menuContent), AnyView(previewContent))
                }
            )
        )
    }

    /// Identifies this view as the source of a context menu
    /// associated with the data type when used with `contextMenu(for:content:)`
    /// or `contextMenu(for:content:preview:)`.
    func matchedContextMenu<V>(for value: V) -> some View {
        modifier(
            EnvironmentContextMenu.Extractor(
                value: value
            )
        )
    }

    /// Identifies this view as the source of a context menu
    /// associated with the data type when used with `contextMenu(for:content:)`
    /// or `contextMenu(for:content:preview:)` but allows local preview
    /// creation.
    func matchedContextMenu<V>(
        for value: V,
        @ViewBuilder preview: @escaping () -> some View
    ) -> some View {
        modifier(
            EnvironmentContextMenu.Extractor(
                value: value,
                preview: { _ in AnyView(preview()) }
            )
        )
    }
}
