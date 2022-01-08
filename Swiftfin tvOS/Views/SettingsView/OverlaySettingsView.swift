//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import Defaults
import SwiftUI

struct OverlaySettingsView: View {
    
    @Default(.shouldShowPlayPreviousItem) var shouldShowPlayPreviousItem
    @Default(.shouldShowPlayNextItem) var shouldShowPlayNextItem
    @Default(.shouldShowAutoPlay) var shouldShowAutoPlay
    
    var body: some View {
        Form {
            Section(header: Text("Overlay")) {
                
                Toggle("\(Image(systemName: "chevron.left.circle")) Play Previous Item", isOn: $shouldShowPlayPreviousItem)
                Toggle("\(Image(systemName: "chevron.right.circle")) Play Next Item", isOn: $shouldShowPlayNextItem)
                Toggle("\(Image(systemName: "play.circle.fill")) Auto Play", isOn: $shouldShowAutoPlay)
            }
        }
    }
}
