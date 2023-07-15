//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import UIKit

// A more general derivative of
// https://stackoverflow.com/questions/65812080/introspect-library-uirefreshcontrol-with-swiftui-not-working
final class RefreshHelper {
    var refreshControl: UIRefreshControl?
    var refreshAction: (() -> Void)?
    private var lastAutomaticRefresh = Date()

    @objc
    func didRefresh() {
        guard let refreshControl = refreshControl else { return }
        refreshAction?()
        refreshControl.endRefreshing()
    }
}

// MARK: - automatic refreshing

extension RefreshHelper {
    private static let timeUntilStale = TimeInterval(60)

    func refreshStaleData() {
        guard isStale else { return }
        lastAutomaticRefresh = .now
        refreshAction?()
    }

    private var isStale: Bool {
        lastAutomaticRefresh.addingTimeInterval(Self.timeUntilStale) < .now
    }
}
