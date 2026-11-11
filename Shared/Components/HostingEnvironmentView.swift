//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: See if can be consolidated with HostingController

/// Container view for forwarding a subset of environment values
/// that all hosting environments should have access to.
struct HostingEnvironmentView<Content: View>: View {

    let content: Content
    var environment: EnvironmentValues

    @ContentBuilder
    var body: some View {
        content
            .environment(\.theme, environment.theme)
    }
}
