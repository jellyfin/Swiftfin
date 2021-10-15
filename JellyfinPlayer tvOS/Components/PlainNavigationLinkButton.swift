//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

struct PlainNavigationLinkButtonStyle: ButtonStyle {
      func makeBody(configuration: Self.Configuration) -> some View {
          PlainNavigationLinkButton(configuration: configuration)
      }
}

struct PlainNavigationLinkButton: View {
    let configuration: ButtonStyle.Configuration

    var body: some View {
        configuration.label
    }
}
