//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - BrunoCollectionArtwork

//
// The at-rest background imagery for the Collections category tiles. Replaces the flat per-category
// gradient with a bundled photo (dimmed behind the title). Two cadences:
//   • Non-seasonal categories pick ONE day-stable image (swaps daily; same within a day across
//     relaunches). No on-screen animation.
//   • The Seasonal category is date-gated to a gapless yearly calendar (Halloween → Christmas →
//     Winter → …); windows with 2+ images slow cross-fade. See `BrunoCollectionArtBackground`.
//
// Asset names map 1:1 to imagesets in Assets.xcassets/BrunoCollections. Categories with no art
// (e.g. Studios) return nil/empty and keep their gradient.
enum BrunoCollectionArtwork {

    /// Non-seasonal category (lowercased name) → its bundled art assets, in catalog-name form.
    private static let byCategory: [String: [String]] = [
        "new releases": ["NewReleases01", "NewReleases02", "NewReleases03"],
        "directors": ["Directors01", "Directors02", "Directors03", "Directors04"],
        "boxed sets": ["BoxedSets01", "BoxedSets02"],
        "curated": ["Curated01", "Curated02"],
        "decades": ["Decades01", "Decades02", "Decades03"],
        "genres": ["Genre01", "Genre02"],
    ]

    static func isSeasonal(_ name: String) -> Bool {
        name.lowercased() == "seasonal"
    }

    /// Sep 21 – Dec 31 (Halloween through the end of Christmas): the Seasonal tile is promoted to
    /// 2nd place, right after New Releases. The rest of the year it keeps its default last slot.
    /// Same start anchor as the Halloween art window.
    static func seasonalPromoted(on date: Date = Date()) -> Bool {
        let cal = Calendar.current
        let md = cal.component(.month, from: date) * 100 + cal.component(.day, from: date)
        return md >= 921 && md <= 1231
    }

    /// One day-stable art asset for a non-seasonal category. Deterministic per day (so it survives an
    /// app relaunch) and salted by name so cards don't all advance in lockstep. nil ⇒ no art for this
    /// category (e.g. Studios) — keep the gradient.
    static func dailyAsset(for name: String, date: Date = Date()) -> String? {
        guard let options = byCategory[name.lowercased()], options.isNotEmpty else { return nil }
        let day = Int(date.timeIntervalSince1970 / 86400)
        let salt = name.lowercased().unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let i = ((day + salt) % options.count + options.count) % options.count
        return options[i]
    }

    /// Seasonal art for `date` — a gapless yearly calendar evaluated by month/day, so each window
    /// repeats every year. Windows with 2+ assets slow cross-fade; a single asset holds. (Owner's
    /// anchor: Halloween runs 9/21 and cycles out 11/1.)
    static func seasonalAssets(for date: Date = Date()) -> [String] {
        let cal = Calendar.current
        let md = cal.component(.month, from: date) * 100 + cal.component(.day, from: date)
        switch md {
        case 201 ... 214: // Valentine's: Feb 1–14
            return ["Seasonal06ValentinesDay"]
        case 320 ... 531: // Spring: Mar 20–May 31
            return ["SeasonalSpring"]
        case 601 ... 920: // Summer: Jun 1–Sep 20
            return ["Seasonal07Summer"]
        case 921 ... 1031: // Halloween: Sep 21–Oct 31
            return ["Seasonal02Halloween", "Seasonal04Halloween"]
        case 1101 ... 1130: // Fall / Thanksgiving: Nov 1–30
            return ["Seasonal03FallThanksgiving", "Seasonal08Thanksgiving"]
        case 1201 ... 1231: // Christmas: Dec 1–31
            return ["Seasonal01CHRISTMAS", "Seasonal05Christmas"]
        default: // Winter: Jan, and Feb 15–Mar 19
            return ["SeasonalWinter"]
        }
    }
}

// MARK: - BrunoCollectionArtBackground

//
// The tile's at-rest background: brand gradient base (fallback + legibility backstop) with the
// category photo on top, dimmed behind the title. Drop-in replacement for the gradient ZStack that
// used to live in `BrunoCategoryTile`'s `background:` closure.
struct BrunoCollectionArtBackground: View {

    let categoryName: String
    let palette: (top: Color, bottom: Color, underline: Color)

    var body: some View {
        ZStack {
            // Brand gradient base — the fallback for categories without art (Studios) and a backstop
            // behind every photo so a missing asset still reads as a branded tile.
            LinearGradient(
                colors: [palette.top, palette.bottom],
                startPoint: .top,
                endPoint: .bottom
            )

            if BrunoCollectionArtwork.isSeasonal(categoryName) {
                BrunoSeasonalArtCycle()
            } else if let asset = BrunoCollectionArtwork.dailyAsset(for: categoryName) {
                BrunoCollectionArtImage(asset: asset)
            }

            // Legibility wash where the label sits (preserved from the original tile).
            LinearGradient(
                colors: [.clear, .black.opacity(0.35)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - BrunoCollectionArtImage

//
// A single bundled photo, aspect-filled to the tile and uniformly dimmed so white Oswald reads over
// any image (matches the focus-art dim treatment, lighter so the photo still reads at rest).
private struct BrunoCollectionArtImage: View {

    let asset: String

    var body: some View {
        Image(asset)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .overlay(Color.black.opacity(0.45))
    }
}

// MARK: - BrunoSeasonalArtCycle

//
// The Seasonal tile's date-gated background. Resolves the active window's assets on appear; a single
// asset holds, 2+ slow cross-fade (hold + gentle dissolve). Reduce Motion holds the first frame. The
// timer is cancelled on disappear so it never runs off-screen.
private struct BrunoSeasonalArtCycle: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State
    private var assets: [String] = []
    @State
    private var index = 0
    @State
    private var cycle: Task<Void, Never>?

    private static let holdSeconds: Double = 7
    private static let dissolveSeconds: Double = 1.2

    var body: some View {
        ZStack {
            ForEach(Array(assets.enumerated()), id: \.offset) { i, asset in
                BrunoCollectionArtImage(asset: asset)
                    .opacity(i == index ? 1 : 0)
            }
        }
        .animation(.easeInOut(duration: Self.dissolveSeconds), value: index)
        .onAppear {
            assets = BrunoCollectionArtwork.seasonalAssets()
            start()
        }
        .onDisappear {
            cycle?.cancel()
            cycle = nil
        }
    }

    private func start() {
        cycle?.cancel()
        guard !reduceMotion, assets.count > 1 else { return }
        cycle = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.holdSeconds))
                if Task.isCancelled { return }
                index = (index + 1) % assets.count
            }
        }
    }
}
