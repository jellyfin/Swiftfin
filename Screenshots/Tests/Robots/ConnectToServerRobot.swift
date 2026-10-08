//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

final class ConnectToServerRobot: Robot {

    func connect(to url: String) -> SelectUserRobot {
        let urlField = waitFor(app.textFields[L10n.url])
        type(url, into: urlField)

        let fieldCenter = CGPoint(x: urlField.frame.midX, y: urlField.frame.midY)
        let connectButton = buttons(labeled: L10n.connect)
            .allElementsBoundByIndex
            .min { distance($0.frame, fieldCenter) < distance($1.frame, fieldCenter) }!

        tap(connectButton)

        return SelectUserRobot(app: app)
    }

    private func distance(_ frame: CGRect, _ point: CGPoint) -> CGFloat {
        hypot(frame.midX - point.x, frame.midY - point.y)
    }
}
