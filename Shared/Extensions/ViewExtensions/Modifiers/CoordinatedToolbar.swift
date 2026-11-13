//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CoordinatedToolbarItem {

    enum Order: Int {

        case leading
        case automatic
        case trailing
    }

    fileprivate let id: String?
    fileprivate let order: Order
    fileprivate let content: AnyView

    init(
        id: String? = nil,
        order: Order = .automatic,
        @ContentBuilder content: () -> some View
    ) {
        self.id = id
        self.order = order
        self.content = AnyView(content())
    }
}

typealias CoordinatedToolbarContentBuilder = ArrayBuilder<CoordinatedToolbarItem>

private struct ResolvedCoordinatedToolbarItem: Identifiable {

    struct ID: Hashable {

        let source: UUID
        let item: AnyHashable
    }

    let id: ID
    let order: CoordinatedToolbarItem.Order
    let content: AnyView
}

private struct CoordinatedToolbarContentKey: PreferenceKey {

    static var defaultValue: [ResolvedCoordinatedToolbarItem] {
        []
    }

    static func reduce(value: inout [ResolvedCoordinatedToolbarItem], nextValue: () -> [ResolvedCoordinatedToolbarItem]) {
        value.append(contentsOf: nextValue())
    }
}

private extension EnvironmentValues {

    @Entry
    var isToolbarCoordinated: Bool = false
}

private struct CoordinatedToolbarContent: View {

    let items: [ResolvedCoordinatedToolbarItem]

    @ContentBuilder
    var body: some View {
        ForEach(items.sorted { $0.order.rawValue < $1.order.rawValue }) { item in
            item.content
        }
    }
}

private struct CoordinatedToolbarModifier: ViewModifier {

    @Environment(\.self)
    private var environment

    @State
    private var sourceID = UUID()

    let items: [CoordinatedToolbarItem]

    private var resolvedItems: [ResolvedCoordinatedToolbarItem] {
        items.enumerated().map { index, item in
            ResolvedCoordinatedToolbarItem(
                id: .init(source: sourceID, item: item.id.map(AnyHashable.init) ?? AnyHashable(index)),
                order: item.order,
                content: AnyView(
                    item.content
                        .environment(\.self, environment)
                        .environment(\.isToolbarCoordinated, false)
                )
            )
        }
    }

    @ContentBuilder
    func body(content: Content) -> some View {
        if environment.isToolbarCoordinated {
            content.transformPreference(CoordinatedToolbarContentKey.self) { items in
                items.append(contentsOf: resolvedItems)
            }
        } else {
            content.toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    CoordinatedToolbarContent(items: resolvedItems)
                }
            }
        }
    }
}

private struct CoordinatedToolbarScopeModifier: ViewModifier {

    @ContentBuilder
    func body(content: Content) -> some View {
        content
            .environment(\.isToolbarCoordinated, true)
            .backgroundPreferenceValue(CoordinatedToolbarContentKey.self) { items in
                Color.clear
                    .frame(width: 0, height: 0)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            CoordinatedToolbarContent(items: items)
                        }
                    }
            }
            .transformPreference(CoordinatedToolbarContentKey.self) { $0.removeAll() }
    }
}

extension View {

    @ContentBuilder
    func coordinatedToolbarScope() -> some View {
        modifier(CoordinatedToolbarScopeModifier())
    }

    @ContentBuilder
    func coordinatedToolbar(
        @CoordinatedToolbarContentBuilder content: () -> [CoordinatedToolbarItem]
    ) -> some View {
        modifier(CoordinatedToolbarModifier(items: content()))
    }
}
