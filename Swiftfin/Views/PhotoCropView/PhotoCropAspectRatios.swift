//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum AspectRatios: Identifiable, Displayable, CaseIterable {

    case free
    case oneToOne
    case twoToThree
    case threeToTwo
    case fourToThree
    case sixteenToNine
    case twentyFourToSeven

    var id: String {
        displayTitle
    }

    var displayTitle: String {
        guard let width, let height else { return L10n.custom }
        return "\(width):\(height)"
    }

    var ratio: Double? {
        guard let width, let height else { return nil }
        return Double(width) / Double(height)
    }

    private var width: Int? {
        switch self {
        case .free:
            nil
        case .oneToOne:
            1
        case .twoToThree:
            2
        case .threeToTwo:
            3
        case .fourToThree:
            4
        case .sixteenToNine:
            16
        case .twentyFourToSeven:
            24
        }
    }

    private var height: Int? {
        switch self {
        case .free:
            nil
        case .oneToOne:
            1
        case .twoToThree:
            3
        case .threeToTwo:
            2
        case .fourToThree:
            3
        case .sixteenToNine:
            9
        case .twentyFourToSeven:
            7
        }
    }
}
