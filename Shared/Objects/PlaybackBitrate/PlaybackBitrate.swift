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

    /// Hard app ceiling. "Maximum" — and the adaptive `auto` network test — never exceed this, so any
    /// source at or below 20 Mbps Direct Plays and only higher-bitrate sources are transcoded down.
    static let ceiling = 20_000_000 // 20 Mbps

    /// Bitrate-only options offered in the UI, all at or below the 20 Mbps `ceiling`. "Maximum" IS the
    /// ceiling (Direct Play up to 20 Mbps); presets above it are omitted since they'd clamp to the same
    /// value. (The full enum is kept so any previously-stored higher value still resolves — clamped.)
    static var allCases: [PlaybackBitrate] {
        [.max, .auto, .mbps15, .mbps10, .mbps8, .mbps6, .mbps4, .mbps3, .kbps1500, .kbps720, .kbps420]
    }

    var displayTitle: String {
        switch self {
        case .auto:
            L10n.auto
        case .max:
            L10n.bitrateMax
        case .mbps120:
            L10n.bitrateMbps120
        case .mbps80:
            L10n.bitrateMbps80
        case .mbps60:
            L10n.bitrateMbps60
        case .mbps40:
            L10n.bitrateMbps40
        case .mbps20:
            L10n.bitrateMbps20
        case .mbps15:
            L10n.bitrateMbps15
        case .mbps10:
            L10n.bitrateMbps10
        case .mbps8:
            L10n.bitrateMbps8
        case .mbps6:
            L10n.bitrateMbps6
        case .mbps4:
            L10n.bitrateMbps4
        case .mbps3:
            L10n.bitrateMbps3
        case .kbps1500:
            L10n.bitrateKbps1500
        case .kbps720:
            L10n.bitrateKbps720
        case .kbps420:
            L10n.bitrateKbps420
        }
    }

    func getMaxBitrate() async throws -> Int {

        // Every selection is clamped to the 20 Mbps ceiling: "Maximum" → 20 Mbps, explicit caps use
        // their stated value, and `auto`'s measured speed is also capped at 20 Mbps. The server then
        // Direct Plays anything at or below the result and only transcodes sources above it.
        guard self == .auto else { return min(rawValue, Self.ceiling) }

        let bitrateTestSize = Defaults[.VideoPlayer.appMaximumBitrateTest]
        let tested = try await testBitrate(with: bitrateTestSize.rawValue)
        return min(tested, Self.ceiling)
    }

    private func testBitrate(with testSize: Int) async throws -> Int {
        precondition(testSize > 0, "testSize must be greater than zero")

        guard let userSession = Container.shared.currentUserSession() else {
            throw UserSessionError.missingCurrentSession
        }

        let testStartTime = Date()
        let _ = try await userSession.client.send(Paths.getBitrateTestBytes(size: testSize))
        let testDuration = Date().timeIntervalSince(testStartTime)
        let testSizeBits = Double(testSize * 8)
        let testBitrate = testSizeBits / testDuration

        return clamp(Int(testBitrate), min: 1_500_000, max: Int(Int32.max))
    }
}
