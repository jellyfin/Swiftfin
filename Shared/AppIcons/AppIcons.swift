//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import UIKit

protocol AppIcon: CaseIterable, Identifiable, Displayable, RawRepresentable {
    var iconName: String { get }
    static var tag: String { get }

    static func createCase(iconName: String) -> Self?
}

extension AppIcon where ID == String, RawValue == String {

    var iconName: String {
        "AppIcon-\(Self.tag)-\(rawValue)"
    }

    var id: String {
        iconName
    }

    static func createCase(iconName: String) -> Self? {
        let split = iconName.split(separator: "-")
        guard split.count == 3, split[1] == tag else { return nil }

        return Self(rawValue: String(split[2]))
    }
}
