//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import SwiftUI

typealias EnvironmentContextMenuPair = (items: AnyView, preview: AnyView?)
typealias ContextMenuRegistry = TypeKeyedDictionary<(Any) -> EnvironmentContextMenuPair>

extension EnvironmentValues {

    @Entry
    var contextMenuRegistry: ContextMenuRegistry = .init()
}

extension View {

    func removeContextMenu<V>(for type: V.Type) -> some View {
        modifier(
            ForTypeInEnvironment<V, (Any) -> EnvironmentContextMenuPair>.SetValue(
                { _ in { _ in (AnyView(EmptyView()), nil) } },
                for: \.contextMenuRegistry
            )
        )
    }

    /// Associates a context menu with a data type for use within
    /// subviews within the container.
    func contextMenu<V>(
        for type: V.Type,
        @ViewBuilder content: @escaping (V) -> some View
    ) -> some View {
        contextMenu(
            for: type,
            content: { _, v in content(v) }
        )
    }

    func contextMenu<V>(
        for type: V.Type,
        @ViewBuilder content: @escaping (V, NavigationCoordinator.Router) -> some View
    ) -> some View {
        EnvironmentValueReader(\.router) { router in
            contextMenu(
                for: type,
                content: { _, v in content(v, router) }
            )
        }
    }

    /// Associates a context menu and preview with a data type for
    /// use within subviews within the container.
    func contextMenu<V>(
        for type: V.Type,
        @ViewBuilder content: @escaping (V) -> some View,
        @ViewBuilder preview: @escaping (V) -> some View
    ) -> some View {
        contextMenu(
            for: type,
            content: { _, v in content(v) },
            preview: { _, v in preview(v) }
        )
    }

    func contextMenu<V>(
        for type: V.Type,
        @ViewBuilder content: @escaping (EnvironmentContextMenuPair?, V) -> some View
    ) -> some View {
        modifier(
            ForTypeInEnvironment<V, (Any) -> EnvironmentContextMenuPair>.SetValue(
                { existing in
                    { value in
                        let content = content(existing?(value as! V), value as! V)
                        return (AnyView(content), nil)
                    }
                },
                for: \.contextMenuRegistry
            )
        )
    }

    func contextMenu<V>(
        for type: V.Type,
        @ViewBuilder content: @escaping (EnvironmentContextMenuPair?, V) -> some View,
        @ViewBuilder preview: @escaping (EnvironmentContextMenuPair?, V) -> some View
    ) -> some View {
        modifier(
            ForTypeInEnvironment<V, (Any) -> EnvironmentContextMenuPair>.SetValue(
                { existing in
                    { value in
                        let content = content(existing?(value as! V), value as! V)
                        let preview = preview(existing?(value as! V), value as! V)

                        return (AnyView(content), AnyView(preview))
                    }
                },
                for: \.contextMenuRegistry
            )
        )
    }

    /// Identifies this view as the source of a context menu
    /// associated with the data type when used with `contextMenu(for:content:)`
    /// or `contextMenu(for:content:preview:)`.
    func matchedContextMenu(for value: some Any) -> some View {
        modifier(
            ForTypeInEnvironment<V, (Any) -> EnvironmentContextMenuPair>.GetValue(
                for: \.contextMenuRegistry
            ) { contextMenuFunction in
                let evaluatedContextMenu = contextMenuFunction(value)

                if let preview = evaluatedContextMenu.preview {
                    self
                        .contextMenu(
                            menuItems: { evaluatedContextMenu.items },
                            preview: { preview }
                        )
                } else {
                    self
                        .contextMenu(
                            menuItems: { evaluatedContextMenu.items }
                        )
                }
            }
        )
    }

    /// Identifies this view as the source of a context menu
    /// associated with the data type when used with `contextMenu(for:content:)`
    /// or `contextMenu(for:content:preview:)` with local preview
    /// creation.
    func matchedContextMenu(
        for value: some Any,
        @ViewBuilder preview: @escaping () -> some View
    ) -> some View {
        modifier(
            ForTypeInEnvironment<V, (Any) -> EnvironmentContextMenuPair>.GetValue(
                for: \.contextMenuRegistry
            ) { contextMenuFunction in
                let evaluatedContextMenu = contextMenuFunction(value)

                self
                    .contextMenu(
                        menuItems: { evaluatedContextMenu.items },
                        preview: preview
                    )
            }
        )
    }
}
