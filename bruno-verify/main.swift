//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// Shim for the Swiftfin `isNotEmpty` idiom used by BrunoRNG (defined app-side normally).
extension Collection {
    var isNotEmpty: Bool {
        !isEmpty
    }
}

func approxEqual(_ a: Double, _ b: Double, _ eps: Double = 1e-12) -> Bool {
    abs(a - b) <= eps
}

var failures = 0
func check(_ name: String, _ cond: Bool) {
    print((cond ? "  ok  " : "FAIL  ") + name)
    if !cond { failures += 1 }
}

// Reference sequences captured from the JS mulberry32 (seed 12345 and 1).
let expected: [UInt32: [Double]] = [
    12345: [
        0.97972826776094735,
        0.30675226449966431,
        0.48420542152598500,
        0.81793441250920296,
        0.50942836934700608,
        0.34747186047025025,
    ],
    1: [
        0.62707394058816135,
        0.00273572118021548,
        0.52744703995995224,
        0.98105096747167408,
        0.96837789821438491,
        0.28110350295901299,
    ],
]

for (seed, ref) in expected {
    var rng = BrunoRNG(seed: seed)
    for (i, want) in ref.enumerated() {
        let got = rng.nextUnit()
        check("mulberry32 seed=\(seed) [\(i)] \(got)", approxEqual(got, want))
    }
}

// Determinism: same seed -> identical shuffle; different seed -> (almost surely) different.
let deck = Array(0 ..< 24)
let a = BrunoRNG.shuffled(deck, seed: 777)
let b = BrunoRNG.shuffled(deck, seed: 777)
let c = BrunoRNG.shuffled(deck, seed: 778)
check("same seed -> same shuffle", a == b)
check("different seed -> different shuffle", a != c)
check("shuffle is a permutation", a.sorted() == deck)

// subSeed wraps at 32 bits like JS (no trap).
let s = BrunoRNG.subSeed(0xFFFF_FFFF, 97, 3, 13)
check("subSeed wraps without trapping (= \(s))", true)

if failures == 0 {
    print("\nALL RNG CHECKS PASSED")
    exit(0)
} else {
    print("\n\(failures) RNG CHECK(S) FAILED")
    exit(1)
}
