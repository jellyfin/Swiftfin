//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: rework to `PosterEnvironment`

extension EnvironmentValues {

    @Entry
    var customEnvironmentValueRegistry: TypeKeyedDictionary<(Any) -> any WithDefaultValue> = .init()
}

extension View {

    @ViewBuilder
    func customEnvironment<P: Poster>(
        for type: P.Type,
        value: P.Environment
    ) -> some View where P.Environment: WithDefaultValue {
        modifier(
            ForTypeInEnvironment<P, (Any) -> any WithDefaultValue>.SetValue(
                { _ in { _ in value } },
                for: \.customEnvironmentValueRegistry
            )
        )
    }
}
