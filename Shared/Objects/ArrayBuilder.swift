//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

@resultBuilder
public enum ArrayBuilder<Component> {

    public static func buildBlock(_ components: [Component]...) -> [Component] {
        components.flattened()
    }

    public static func buildExpression(_ expression: Component) -> [Component] {
        [expression]
    }

    public static func buildOptional(_ component: [Component]?) -> [Component] {
        component ?? []
    }

    public static func buildEither(first component: [Component]) -> [Component] {
        component
    }

    public static func buildEither(second component: [Component]) -> [Component] {
        component
    }

    public static func buildArray(_ components: [[Component]]) -> [Component] {
        components.flattened()
    }

    public static func buildExpression(_ expression: [Component]) -> [Component] {
        expression
    }

    static func buildExpression<T: RawRepresentable>(_ expression: T) -> [Component] where T.RawValue == Component {
        [expression.rawValue]
    }

    static func buildExpression<T: RawRepresentable>(_ expression: [T]) -> [Component] where T.RawValue == Component {
        expression.map(\.rawValue)
    }
}
