//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// MARK: - BrunoRNG

//
// A faithful Swift port of the prototype's `mulberry32` PRNG (Bruno.dc.html `rng` L453).
// Determinism is the whole point: a single seed fully reproduces a home screen, so the
// experience is "never the same twice" yet recognizable within a day (see PRODUCT_SPEC §4).
//
// JS uses `Math.imul` and `>>> 0` — i.e. 32-bit wraparound arithmetic. Swift must use the
// wrapping operators `&+` / `&*` (plain `+`/`*` would TRAP on overflow) and `UInt32`
// throughout. `>>` on `UInt32` is the logical shift that matches JS `>>>`. Verified against
// a captured JS sequence (see Scripts/bruno-rng-verify.swift).
struct BrunoRNG {

    private var state: UInt32

    init(seed: UInt32) {
        // mulberry32 is happy with any 32-bit seed, including 0.
        self.state = seed
    }

    /// Convenience for the common `seed: Int` call sites; wraps into 32 bits like JS `>>> 0`.
    init(seed: Int) {
        self.init(seed: UInt32(truncatingIfNeeded: seed))
    }

    /// Next value in `[0, 1)` — mirrors the JS closure returned by `rng(seed)`.
    mutating func nextUnit() -> Double {
        state = state &+ 0x6D2B_79F5
        var r = (state ^ (state >> 15)) &* (1 | state)
        r = r ^ (r &+ ((r ^ (r >> 7)) &* (61 | r)))
        r = r ^ (r >> 14)
        return Double(r) / 4_294_967_296
    }

    /// Seeded Fisher–Yates — mirrors the prototype's `shuf(arr, rnd)` (Bruno.dc.html L454).
    mutating func shuffled<T>(_ array: [T]) -> [T] {
        var a = array
        var i = a.count - 1
        while i > 0 {
            let j = Int(nextUnit() * Double(i + 1))
            a.swapAt(i, j)
            i -= 1
        }
        return a
    }

    /// First element of a seeded shuffle, or nil if empty. Mirrors `shuf(arr, rnd)[0]`.
    mutating func pick<T>(_ array: [T]) -> T? {
        guard array.isNotEmpty else { return nil }
        return shuffled(array).first
    }
}

extension BrunoRNG {

    /// Pure, stateless seeded shuffle for call sites that don't thread a generator.
    /// Same result as `var rng = BrunoRNG(seed:); rng.shuffled(array)`.
    static func shuffled<T>(_ array: [T], seed: UInt32) -> [T] {
        var rng = BrunoRNG(seed: seed)
        return rng.shuffled(array)
    }

    /// Derive a sub-seed the way the prototype's explore generators do
    /// (`rng(seed*97 + i*13)` etc.), with 32-bit wraparound.
    static func subSeed(_ base: UInt32, _ multiplier: UInt32, _ index: UInt32, _ indexMultiplier: UInt32) -> UInt32 {
        base &* multiplier &+ index &* indexMultiplier
    }
}
