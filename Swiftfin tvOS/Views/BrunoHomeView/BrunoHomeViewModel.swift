//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI

// MARK: - BrunoHomeViewModel

//
// Uses the HAND-WRITTEN `Stateful` protocol (Action/State/respond/send) — NOT the `@Stateful`
// macro (plan §C3). On `refresh`: load the snapshot once, build the seeded plan, realize each
// shelf into a `BrunoShelfViewModel` and `await` them concurrently, then publish. `shuffle`
// re-rolls the seed and rebuilds; `appendExplore` grows the dynamic tail (it lives here, not
// on a paging VM). Seed is day-stable and persisted in `Defaults` (new day → new seed).
@MainActor
final class BrunoHomeViewModel: ViewModel, Stateful {

    enum Action: Equatable {
        case refresh
        case backgroundRefresh
        case shuffle
        case appendExplore
        /// Re-pick the hero spotlights only (cheap, local) — on every home (re)entry / after playback.
        case reshuffleHero
    }

    enum State: Hashable {
        case content
        case error(ErrorMessage)
        case initial
        case refreshing
    }

    @Published
    var state: State = .initial

    @Published
    private(set) var sections: [BrunoShelfViewModel] = []
    @Published
    private(set) var heroItems: [BaseItemDto] = []

    /// Bumped on Shuffle so the view can scroll back to the top.
    @Published
    private(set) var scrollResetToken = 0

    private(set) var seed: UInt32

    private var snapshot: BrunoLibrarySnapshot = .empty
    /// The fetched hero candidate pool (high-rated movies); re-shuffled locally on each (re)entry.
    private var heroSuperset: [BaseItemDto] = []
    private var explorePage = 0
    /// Content already on screen (by `BrunoShelf.dedupeKey`) so the explore tail never repeats a
    /// collection it (or the spine) already showed — including across infinite-scroll pages.
    private var seenDedupeKeys: Set<String> = []
    /// Set once the explore tail can produce nothing new, so the bottom sentinel stops re-firing.
    private var exploreExhausted = false
    private var refreshTask: AnyCancellable?
    private var appendTask: AnyCancellable?

    override init() {
        self.seed = Self.resolveDaySeed()
        super.init()
        #if DEBUG
        assert(BrunoHomePlan.selfCheckPassed(), "BrunoHomePlan determinism self-check failed")
        #endif
    }

    func respond(to action: Action) -> State {
        switch action {
        case .refresh, .backgroundRefresh:
            // Cancel any in-flight explore append too, so a stale-seed append can't resume after
            // the rebuild and graft old shelves onto the new plan (its `Task.isCancelled` guards
            // only protect against this if the task is actually cancelled here).
            appendTask?.cancel()
            refreshTask?.cancel()
            refreshTask = Task { [weak self] in
                await self?.performRefresh()
            }
            .asAnyCancellable()
            return .refreshing

        case .shuffle:
            seed = Self.reseedRandom()
            explorePage = 0
            scrollResetToken &+= 1
            appendTask?.cancel()
            refreshTask?.cancel()
            refreshTask = Task { [weak self] in
                await self?.performRefresh()
            }
            .asAnyCancellable()
            return .refreshing

        case .appendExplore:
            guard state == .content, !exploreExhausted, sections.count < BrunoHomePlan.shelfCap else { return state }
            appendTask?.cancel()
            appendTask = Task { [weak self] in
                await self?.performAppendExplore()
            }
            .asAnyCancellable()
            return state

        case .reshuffleHero:
            reshuffleHero()
            return state
        }
    }

    /// Re-pick the 5 hero spotlights from the already-fetched superset in a fresh random order.
    /// Local and instant (no network), so it's safe to run on every home (re)appearance. No-op
    /// until the superset has been fetched by the first refresh.
    private func reshuffleHero() {
        guard heroSuperset.isNotEmpty else { return }
        heroItems = Array(BrunoRNG.shuffled(heroSuperset, seed: UInt32.random(in: 1 ... UInt32.max)).prefix(5))
    }

    // MARK: Work

    private func performRefresh() async {
        guard let userSession else {
            state = .error(.init("Not signed in"))
            return
        }

        // forceReload: Home always refreshes fresh (unchanged behavior), but stores the result so
        // Collections / drill-ins can reuse it instead of refetching the whole library.
        let snapshot = await BrunoLibrarySnapshot.loadShared(
            client: userSession.client,
            userID: userSession.user.id,
            forceReload: true
        )

        guard !Task.isCancelled else { return }
        self.snapshot = snapshot

        async let heroTask = loadHero(session: userSession)

        let plan = BrunoHomePlan.build(seed: seed, snapshot: snapshot, now: Date())
        let sectionVMs = plan.map { BrunoShelfViewModel(shelf: $0) }
        await withTaskGroup(of: Void.self) { group in
            for section in sectionVMs {
                group.addTask { await section.load() }
            }
        }

        guard !Task.isCancelled else { return }

        heroItems = await heroTask
        let kept = sectionVMs.filter(\.shouldDisplay)
        sections = kept
        seenDedupeKeys = Set(kept.map(\.shelf.dedupeKey))
        explorePage = 0
        exploreExhausted = false
        state = .content
    }

    private func performAppendExplore() async {
        guard let userSession, !exploreExhausted else { return }

        // Advance the page regardless of yield so an empty batch can't busy-loop the sentinel.
        let page = explorePage + 1
        explorePage = page

        // Filter out collections already shown (spine or earlier pages) BEFORE fetching.
        let newShelves = BrunoHomePlan.appendExplore(
            seed: seed,
            page: page,
            alreadyShown: sections.count,
            snapshot: snapshot,
            now: Date()
        )
        .filter { !seenDedupeKeys.contains($0.dedupeKey) }

        if newShelves.isEmpty {
            // Walked a full lap of the key pool with nothing new → stop appending.
            if page >= BrunoHomePlan.exploreKeys.count { exploreExhausted = true }
            return
        }

        let newVMs = newShelves.map { BrunoShelfViewModel(shelf: $0) }
        await withTaskGroup(of: Void.self) { group in
            for section in newVMs {
                group.addTask { await section.load() }
            }
        }

        guard !Task.isCancelled else { return }

        let existingIDs = Set(sections.map(\.id))
        let kept = newVMs.filter { $0.shouldDisplay && !existingIDs.contains($0.id) }
        for section in kept {
            seenDedupeKeys.insert(section.shelf.dedupeKey)
        }
        sections.append(contentsOf: kept)

        if sections.count >= BrunoHomePlan.shelfCap { exploreExhausted = true }
    }

    /// Hero spotlight: fetch a high-rated superset (plan §D), cache it, and return 5 in a fresh
    /// random order. Unlike the day-stable shelf plan, the hero is intentionally random on every
    /// entry — `reshuffleHero()` re-picks from the cached superset on each re-appearance.
    private func loadHero(session: UserSession) async -> [BaseItemDto] {
        var parameters = Paths.GetItemsParameters()
        parameters.userID = session.user.id
        parameters.isRecursive = true
        parameters.includeItemTypes = [.movie]
        parameters.minCommunityRating = 8.2
        parameters.sortBy = [.communityRating]
        parameters.sortOrder = [.descending]
        parameters.fields = [.overview, .genres]
        parameters.enableUserData = true
        parameters.limit = 30
        do {
            let items = try await session.client.send(Paths.getItems(parameters: parameters)).value.items ?? []
            heroSuperset = items
            return Array(BrunoRNG.shuffled(items, seed: UInt32.random(in: 1 ... UInt32.max)).prefix(5))
        } catch {
            return []
        }
    }

    // MARK: Seed

    nonisolated static func todayStamp() -> Int {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return (components.year ?? 2026) * 10000 + (components.month ?? 1) * 100 + (components.day ?? 1)
    }

    /// Day-stable seed: reuse the persisted seed if it was minted today, else mint from today's stamp.
    private nonisolated static func resolveDaySeed() -> UInt32 {
        let today = todayStamp()
        if Defaults[.brunoSeedDay] == today, Defaults[.brunoSeed] != 0 {
            return UInt32(truncatingIfNeeded: Defaults[.brunoSeed])
        }
        let seed = UInt32(truncatingIfNeeded: today)
        Defaults[.brunoSeed] = Int(seed)
        Defaults[.brunoSeedDay] = today
        return seed
    }

    /// "Surprise me": a fresh random seed, persisted for the rest of today.
    private nonisolated static func reseedRandom() -> UInt32 {
        let seed = UInt32.random(in: 1 ... UInt32.max)
        Defaults[.brunoSeed] = Int(seed)
        Defaults[.brunoSeedDay] = todayStamp()
        return seed
    }
}
