//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftfinMacros
import Testing

@OptionSet<Int>
private struct Indicators: Codable, Hashable {
    private enum Options: Int {
        case favorited
        case played
        case progress
        case unplayed
    }

    static var all: Self {
        [.favorited, .played, .progress, .unplayed]
    }
}

private struct StoredIndicators: Swift.OptionSet, Codable {
    let rawValue: Int
}

@OptionSet<UInt8>
public struct SparseOptions: Sendable {
    private enum Options: Int {
        case first = 1
        case highest = 7
        case third = 3
        case fourth
    }

    public static var combined: Self {
        [.first, .highest]
    }
}

@SwiftfinMacros.OptionSet<Swift.Int>
private struct ExplicitConformance: Swift.OptionSet {
    private enum Options: Int {
        case up
        case down
        case `default`
    }
}

@OptionSet<Int>
private struct TrailerOptions: Codable, CaseIterable {
    private enum Options: Int {
        case local
        case external
        case none
    }

    static var all: Self {
        [.local, .external]
    }

    static var allCases: [Self] {
        [.all, .local, .external, .none]
    }
}

struct OptionSetTests {

    @Test
    func `bit positions and empty initialization are preserved`() {
        #expect(Indicators.favorited.rawValue == 1)
        #expect(Indicators.played.rawValue == 2)
        #expect(Indicators.progress.rawValue == 4)
        #expect(Indicators.unplayed.rawValue == 8)
        #expect(Indicators.all.rawValue == 15)
        #expect(Indicators().isEmpty)
        #expect(Indicators(rawValue: 0).isEmpty)
    }

    @Test
    func `generated options support set algebra`() {
        var options: Indicators = [.favorited, .progress]
        #expect(options.contains(.favorited))
        #expect(!options.contains(.played))
        options.insert(.played)
        options.remove(.favorited)
        #expect(options == [.played, .progress])
        #expect(options.union(.unplayed) == [.played, .progress, .unplayed])
        #expect(options.intersection(.all) == options)
        #expect(Indicators.all.subtracting(options) == [.favorited, .unplayed])
    }

    @Test(arguments: [0, 1, 2, 4, 8, 15, 129])
    func `saved raw values and unknown bits round trip`(rawValue: Int) throws {
        let oldData = try JSONEncoder().encode(StoredIndicators(rawValue: rawValue))
        let decoded = try JSONDecoder().decode(Indicators.self, from: oldData)
        #expect(decoded.rawValue == rawValue)
        let newData = try JSONEncoder().encode(decoded)
        #expect(newData == oldData)
        #expect(try JSONDecoder().decode(StoredIndicators.self, from: newData).rawValue == rawValue)
    }

    @Test
    func `sparse reordered positions and narrow raw values work`() {
        #expect(SparseOptions.first.rawValue == 2)
        #expect(SparseOptions.highest.rawValue == 128)
        #expect(SparseOptions.third.rawValue == 8)
        #expect(SparseOptions.fourth.rawValue == 16)
        #expect(SparseOptions.combined.rawValue == 130)
        #expect(SparseOptions(rawValue: 255).contains(.combined))
    }

    @Test
    func `explicit conformance grouped cases and escaped names work`() {
        #expect(ExplicitConformance.up.rawValue == 1)
        #expect(ExplicitConformance.down.rawValue == 2)
        #expect(ExplicitConformance.default.rawValue == 4)
        #expect(ExplicitConformance().isEmpty)
    }

    @Test
    func `trailer none remains a distinct option and allCases stays ordered`() {
        #expect(TrailerOptions.none.rawValue == 4)
        #expect(!TrailerOptions.none.isEmpty)
        #expect(TrailerOptions.all.rawValue == 3)
        #expect(TrailerOptions.allCases.map(\.rawValue) == [3, 1, 2, 4])
    }
}
