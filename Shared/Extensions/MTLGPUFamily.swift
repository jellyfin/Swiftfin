//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Metal

extension MTLGPUFamily: @retroactive Comparable, @retroactive CaseIterable {

    public static var allCases: [MTLGPUFamily] {
        [
            .apple1,
            .apple2,
            .apple3,
            .apple4,
            .apple5,
            .apple6,
            .apple7,
            .apple8,
            .apple9,
            .apple10,
            .mac2,
            .common1,
            .common2,
            .common3,
            .metal3,
        ]
    }

    public static func < (lhs: MTLGPUFamily, rhs: MTLGPUFamily) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension MTLGPUFamily {

    static var current: MTLGPUFamily? {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }

        if let asGPU = allCases
            .filter(\.isAppleSilicon)
            .sorted(by: >)
            .first(where: { device.supportsFamily($0) })
        {
            return asGPU
        }

        if let intelGPU = allCases
            .filter(\.isIntelMac)
            .sorted(by: >)
            .first(where: { device.supportsFamily($0) })
        {
            return intelGPU
        }

        return nil
    }

    // MARK: Hardware Type

    var isAppleSilicon: Bool {
        (1000 ... 1999).contains(rawValue)
    }

    var isIntelMac: Bool {
        (2000 ... 2999).contains(rawValue)
    }

    // MARK: - MPEG / ITU-T

    var supportsHEVCDecode: Bool {
        (isAppleSilicon && self >= .apple3) || isIntelMac
    }

    var supportsVVCDecode: Bool {
        false
    }

    // MARK: - Alliance for Open Media

    var supportsAV1Decode: Bool {
        isAppleSilicon && self >= .apple9
    }

    // MARK: - Google

    var supportsVP8Decode: Bool {
        false
    }

    var supportsVP9Decode: Bool {
        false
    }

    // MARK: HDR

    var supportsHDR10Decode: Bool {
        isAppleSilicon && self >= .apple4
    }

    var supportsHLGDecode: Bool {
        isAppleSilicon && self >= .apple4
    }

    var supportsDolbyVisionDecode: Bool {
        isAppleSilicon && self >= .apple5
    }
}
