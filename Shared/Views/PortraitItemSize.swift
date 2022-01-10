//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

extension View {
    
    /// Applies Portrait Poster frame with proper corner radius ratio against the width
    func portraitPoster(width: CGFloat) -> some View {
        self.frame(width: width, height: width * 1.5)
            .cornerRadius((width * 1.5) / 40)
    }
}
