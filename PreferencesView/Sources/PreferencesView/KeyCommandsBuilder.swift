//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

@resultBuilder
public enum KeyCommandsBuilder {

    public static func buildBlock(_ components: [KeyCommandAction]...) -> [KeyCommandAction] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: KeyCommandAction) -> [KeyCommandAction] {
        [expression]
    }

    public static func buildOptional(_ component: [KeyCommandAction]?) -> [KeyCommandAction] {
        component ?? []
    }

    public static func buildEither(first component: [KeyCommandAction]) -> [KeyCommandAction] {
        component
    }

    public static func buildEither(second component: [KeyCommandAction]) -> [KeyCommandAction] {
        component
    }

    public static func buildArray(_ components: [[KeyCommandAction]]) -> [KeyCommandAction] {
        components.flatMap { $0 }
    }
}
