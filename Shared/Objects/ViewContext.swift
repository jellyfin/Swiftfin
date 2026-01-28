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

    static let isInMenu = ViewContext(rawValue: 1 << 0)
    static let isThumb = ViewContext(rawValue: 1 << 1)
    static let isOverComplexContent = ViewContext(rawValue: 1 << 2)
    static let isInParent = ViewContext(rawValue: 1 << 3)
    static let isInResume = ViewContext(rawValue: 1 << 4)
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
        WithEnvironment(value: \.viewContext) { oldValue in
            self.environment(\.viewContext, oldValue.inserting(context))
        }
    }

    func removingViewContext(_ context: ViewContext) -> some View {
        WithEnvironment(value: \.viewContext) { oldValue in
            self.environment(\.viewContext, oldValue.removing(context))
        }
    }
}
