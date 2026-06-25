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
    /// Bumped at the start of every `performRefresh`. Streaming shelf-inserts and explore appends
    /// are guarded on it so a superseded refresh (e.g. Shuffle restarts the task) can never graft
    /// stale-generation rows onto the new spine. (`Task.isCancelled` covers the same case; the
    /// generation guard is the belt to that suspenders, and survives a same-seed re-refresh.)
    private var refreshGeneration = 0
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

        refreshGeneration &+= 1
        let generation = refreshGeneration

        // WS2: paint instantly from the last session's disk payload (if any), then revalidate from
        // the network and reconcile in place. Cold (no payload, or Shuffle's fresh seed) falls
        // through to the top-down streaming cold path inside `revalidate`.
        let hydrated = await hydrateFromDisk(userSession: userSession, generation: generation)
        await revalidate(userSession: userSession, generation: generation, reconcile: hydrated)
    }

    /// Best-effort instant paint from the disk payload. Returns true iff it painted (so `revalidate`
    /// reconciles in place rather than streaming cold). Seed-guarded so Shuffle never hydrates a
    /// stale-seed spine (INV-5).
    private func hydrateFromDisk(userSession: UserSession, generation: Int) async -> Bool {
        guard let payload = await BrunoHomeCache.shared.load(
            userID: userSession.user.id,
            seed: seed,
            maxAge: 60 * 60 * 24
        ), !Task.isCancelled, generation == refreshGeneration else { return false }

        snapshot = payload.snapshot
        // Let Collections / drill-ins reuse this snapshot in-session too.
        await BrunoLibrarySnapshot.seedCache(payload.snapshot, userID: userSession.user.id)

        let plan = BrunoHomePlan.build(seed: seed, snapshot: payload.snapshot, now: Date())
        let vms = plan.map { BrunoShelfViewModel(shelf: $0) }
        for vm in vms {
            switch vm.shelf.source {
            case let .items(items):
                vm.hydrate(items: items) // reproduced from the cached snapshot
            case .query:
                if let cached = payload.queryItems[vm.id] { vm.hydrate(items: cached) }
            case .resume, .nextUp, .recentlyAdded:
                break // live user-state — filled fresh by revalidate (INV-5)
            }
        }

        let kept = vms.filter(\.shouldDisplay)
        guard kept.isNotEmpty || payload.heroSuperset.isNotEmpty else { return false }

        sections = kept
        seenDedupeKeys = Set(kept.map(\.shelf.dedupeKey))
        heroSuperset = payload.heroSuperset
        reshuffleHero() // instant hero from the cached superset
        explorePage = 0
        exploreExhausted = false
        state = .content
        return true
    }

    /// Network refresh. When `reconcile` is true the spine is already on screen (from disk): load
    /// fresh items and merge by `shelf.id`, reusing the existing VM instances so identity — and
    /// focus — survive (INV-2; rows are height-pinned so no reflow). When false, stream in cold
    /// (top-down, INV-8). Either way the hero publishes the moment it lands (the cold-spinner lever).
    private func revalidate(userSession: UserSession, generation: Int, reconcile: Bool) async {
        let snapshot = await BrunoLibrarySnapshot.loadShared(
            client: userSession.client,
            userID: userSession.user.id,
            forceReload: true
        )
        guard !Task.isCancelled, generation == refreshGeneration else { return }
        self.snapshot = snapshot

        async let heroPublish: Void = publishHero(session: userSession, generation: generation)

        let plan = BrunoHomePlan.build(seed: seed, snapshot: snapshot, now: Date())
        let freshVMs = plan.map { BrunoShelfViewModel(shelf: $0) }

        if reconcile {
            await loadAll(freshVMs)
            guard !Task.isCancelled, generation == refreshGeneration else { return }
            let existingByID = Dictionary(sections.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            var merged: [BrunoShelfViewModel] = []
            for fresh in freshVMs where fresh.shouldDisplay {
                if let existing = existingByID[fresh.id] {
                    existing.hydrate(items: Array(fresh.items)) // update in place, keep identity
                    merged.append(existing)
                } else {
                    merged.append(fresh)
                }
            }
            sections = merged
            seenDedupeKeys = Set(merged.map(\.shelf.dedupeKey))
        } else {
            // Clear the old spine for this fresh roll; shelves stream back in below. Hero stays
            // painted so the gate never drops to a spinner on Shuffle/refresh.
            sections = []
            await streamReveal(freshVMs, generation: generation) { [weak self] vm in
                guard let self, vm.shouldDisplay else { return }
                self.sections.append(vm)
            }
            seenDedupeKeys = Set(sections.map(\.shelf.dedupeKey))
        }

        await heroPublish
        guard !Task.isCancelled, generation == refreshGeneration else { return }
        explorePage = 0
        exploreExhausted = false
        state = .content

        await persistPayload(userID: userSession.user.id)
    }

    /// Load every shelf concurrently with no reveal ordering — used by the reconcile path, which
    /// merges all at once after the spine is already on screen (vs `streamReveal`'s top-down paint).
    private func loadAll(_ vms: [BrunoShelfViewModel]) async {
        await withTaskGroup(of: Void.self) { group in
            for vm in vms {
                group.addTask { await vm.load() }
            }
        }
    }

    /// Persist the current render payload for instant relaunch. Only `.query` items are cached (the
    /// snapshot reproduces `.items`; live rows are never cached — INV-5). The encode runs off-main
    /// inside the `BrunoHomeCache` actor.
    private func persistPayload(userID: String) async {
        let queryItems: [String: [BaseItemDto]] = sections.reduce(into: [:]) { dict, vm in
            if case .query = vm.shelf.source {
                dict[vm.id] = Array(vm.items)
            }
        }
        let payload = BrunoHomePayload(
            savedAt: Date(),
            userID: userID,
            seed: seed,
            snapshot: snapshot,
            heroSuperset: heroSuperset,
            queryItems: queryItems
        )
        await BrunoHomeCache.shared.store(payload)
    }

    /// Load `vms` concurrently, then reveal each in strict plan order (INV-8): shelf *i* is flushed
    /// only once shelves 0…*i* have all finished loading, so `reveal` only ever APPENDS — it never
    /// inserts above visible content. `reveal` decides keep/drop (and any dedupe side effects) at
    /// flush time. Generation-guarded so a superseded refresh can't graft rows.
    private func streamReveal(
        _ vms: [BrunoShelfViewModel],
        generation: Int,
        reveal: @escaping (BrunoShelfViewModel) -> Void
    ) async {
        var loaded: Set<Int> = []
        var nextReveal = 0
        await withTaskGroup(of: Int.self) { group in
            for (index, vm) in vms.enumerated() {
                group.addTask {
                    await vm.load()
                    return index
                }
            }
            for await index in group {
                guard !Task.isCancelled, generation == refreshGeneration else { continue }
                loaded.insert(index)
                while loaded.contains(nextReveal) {
                    reveal(vms[nextReveal])
                    nextReveal += 1
                }
            }
        }
    }

    /// Fetch the hero superset and publish the 5 picks as soon as they land (generation-guarded).
    private func publishHero(session: UserSession, generation: Int) async {
        let hero = await loadHero(session: session)
        guard !Task.isCancelled, generation == refreshGeneration else { return }
        heroItems = hero
    }

    private func performAppendExplore() async {
        guard let userSession, !exploreExhausted else { return }
        // Tie this append to the live refresh generation so a refresh mid-append stops the inserts.
        let generation = refreshGeneration

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
        let existingIDs = Set(sections.map(\.id))

        // Stream the appended shelves in top-down (plan) order, same as performRefresh — so one slow
        // explore query doesn't gate the rest of the page. Dedupe at flush time (keys can repeat
        // within a batch); kept shelves are recorded in `seenDedupeKeys` as they append.
        await streamReveal(newVMs, generation: generation) { [weak self] vm in
            guard let self,
                  vm.shouldDisplay,
                  !existingIDs.contains(vm.id),
                  !self.seenDedupeKeys.contains(vm.shelf.dedupeKey) else { return }
            self.seenDedupeKeys.insert(vm.shelf.dedupeKey)
            self.sections.append(vm)
        }

        guard !Task.isCancelled, generation == refreshGeneration else { return }

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
