//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI

// TODO: move bitrate test to `MediaPlayerManager`

enum PlaybackBitrate: Int, CaseIterable, Displayable, Storable {
    case auto = 0
    case max = 360_000_000
    case mbps120 = 120_000_000
    case mbps80 = 80_000_000
    case mbps60 = 60_000_000
    case mbps40 = 40_000_000
    case mbps20 = 20_000_000
    case mbps15 = 15_000_000
    case mbps10 = 10_000_000
    case mbps8 = 8_000_000
    case mbps6 = 6_000_000
    case mbps4 = 4_000_000
    case mbps3 = 3_000_000
    case kbps1500 = 1_500_000
    case kbps720 = 720_000
    case kbps420 = 420_000

    var displayTitle: String {
        switch self {
        case .auto:
            return L10n.bitrateAuto
        case .max:
            return L10n.bitrateMax
        case .mbps120:
            return L10n.bitrateMbps120
        case .mbps80:
            return L10n.bitrateMbps80
        case .mbps60:
            return L10n.bitrateMbps60
        case .mbps40:
            return L10n.bitrateMbps40
        case .mbps20:
            return L10n.bitrateMbps20
        case .mbps15:
            return L10n.bitrateMbps15
        case .mbps10:
            return L10n.bitrateMbps10
        case .mbps8:
            return L10n.bitrateMbps8
        case .mbps6:
            return L10n.bitrateMbps6
        case .mbps4:
            return L10n.bitrateMbps4
        case .mbps3:
            return L10n.bitrateMbps3
        case .kbps1500:
            return L10n.bitrateKbps1500
        case .kbps720:
            return L10n.bitrateKbps720
        case .kbps420:
            return L10n.bitrateKbps420
        }
    }

    func getMaxBitrate() async throws -> Int {

        guard self == .auto else { return rawValue }

        let bitrateTestSize = Defaults[.VideoPlayer.appMaximumBitrateTest]
        return try await testBitrate(with: bitrateTestSize.rawValue)
    }

    private func testBitrate(with testSize: Int) async throws -> Int {
        precondition(testSize > 0, "testSize must be greater than zero")

        let userSession = Container.shared.currentUserSession()!

        let testStartTime = Date()
        let _ = try await userSession.client.send(Paths.getBitrateTestBytes(size: testSize))
        let testDuration = Date().timeIntervalSince(testStartTime)
        let testSizeBits = Double(testSize * 8)
        let testBitrate = testSizeBits / testDuration

        return clamp(Int(testBitrate), min: 1_500_000, max: Int(Int32.max))
    }
}
