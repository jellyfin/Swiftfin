//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol WithDefaultValue: Equatable {
    static var `default`: Self { get }
}

protocol CustomEnvironmentValue: WithDefaultValue {}

extension EnvironmentValues {

    @Entry
    var customEnvironmentValueRegistry: TypeKeyedDictionary<(Any) -> any CustomEnvironmentValue> = .init()
}

extension View {

    @ViewBuilder
    func customEnvironment<P: Poster>(
        for type: P.Type,
        value: P.Environment
    ) -> some View where P.Environment: CustomEnvironmentValue {
        modifier(
            ForTypeInEnvironment<P, (Any) -> any CustomEnvironmentValue>.SetValue(
                { _ in { _ in value } },
                for: \.customEnvironmentValueRegistry
            )
        )
    }
}
