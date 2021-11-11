//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import UIKit

// A more general derivative of
// https://stackoverflow.com/questions/65812080/introspect-library-uirefreshcontrol-with-swiftui-not-working
class RefreshHelper {
    var refreshControl: UIRefreshControl?
    var refreshAction: (() -> Void)?

    @objc func didRefresh() {
        guard let refreshControl = refreshControl else { return }
        refreshAction?()
        refreshControl.endRefreshing()
    }
}
