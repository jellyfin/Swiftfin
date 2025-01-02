//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Result builder that build a comma-separated string from its components
@resultBuilder
struct CommaStringBuilder<Component> where Component: RawRepresentable<String> {

    static func buildBlock(_ components: String...) -> String {
        components.joined(separator: ",")
    }

    static func buildExpression(_ expression: Component) -> String {
        expression.rawValue
    }

    static func buildExpression(_ expression: [Component]) -> String {
        expression.map(\.rawValue)
            .joined(separator: ",")
    }
}
