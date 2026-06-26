//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol WithViewContext {
    var viewContext: ViewContext { get set }
}

struct ViewContext: OptionSet {

    let rawValue: Int

    static let isListRowSeparatorVisible = ViewContext(rawValue: 1 << 0)
    static let isInMenu = ViewContext(rawValue: 1 << 1)
}

extension EnvironmentValues {

    @Entry
    var viewContext: ViewContext = .init()
}

@propertyWrapper
struct ViewContextContains: DynamicProperty {

    @Environment(\.viewContext)
    private var oldValue: ViewContext

    private let viewContext: ViewContext

    init(_ viewContext: ViewContext) {
        self.viewContext = viewContext
    }

    var wrappedValue: Bool {
        oldValue.contains(viewContext)
    }
}

extension View {

    func withViewContext(_ context: ViewContext) -> some View {
        modifier(InsertingViewContextModifier(insertingContext: context))
    }

    func removingViewContext(_ context: ViewContext) -> some View {
        modifier(RemovingViewContextModifier(removingContext: context))
    }
}

private struct InsertingViewContextModifier: ViewModifier {

    @Environment(\.viewContext)
    private var environmentContext

    let insertingContext: ViewContext

    func body(content: Content) -> some View {
        content.environment(\.viewContext, environmentContext.inserting(insertingContext))
    }
}

private struct RemovingViewContextModifier: ViewModifier {

    @Environment(\.viewContext)
    private var environmentContext

    let removingContext: ViewContext

    func body(content: Content) -> some View {
        content.environment(\.viewContext, environmentContext.removing(removingContext))
    }
}
