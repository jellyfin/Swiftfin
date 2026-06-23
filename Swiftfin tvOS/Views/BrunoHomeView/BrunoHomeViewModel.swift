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
    private var explorePage = 0
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
            refreshTask?.cancel()
            refreshTask = Task { [weak self] in
                await self?.performRefresh()
            }
            .asAnyCancellable()
            return .refreshing

        case .appendExplore:
            guard state == .content, sections.count < BrunoHomePlan.shelfCap else { return state }
            appendTask?.cancel()
            appendTask = Task { [weak self] in
                await self?.performAppendExplore()
            }
            .asAnyCancellable()
            return state
        }
    }

    // MARK: Work

    private func performRefresh() async {
        guard let userSession else {
            state = .error(.init("Not signed in"))
            return
        }

        let snapshot = await BrunoLibrarySnapshot.load(
            client: userSession.client,
            userID: userSession.user.id
        )

        guard !Task.isCancelled else { return }
        self.snapshot = snapshot

        async let heroTask = loadHero(seed: seed, session: userSession)

        let plan = BrunoHomePlan.build(seed: seed, snapshot: snapshot)
        let sectionVMs = plan.map { BrunoShelfViewModel(shelf: $0) }
        await withTaskGroup(of: Void.self) { group in
            for section in sectionVMs {
                group.addTask { await section.load() }
            }
        }

        guard !Task.isCancelled else { return }

        heroItems = await heroTask
        sections = sectionVMs.filter(\.shouldDisplay)
        state = .content
    }

    private func performAppendExplore() async {
        guard let userSession else { return }

        let newShelves = BrunoHomePlan.appendExplore(
            seed: seed,
            page: explorePage + 1,
            alreadyShown: sections.count,
            snapshot: snapshot
        )
        guard newShelves.isNotEmpty else { return }
        explorePage += 1

        let newVMs = newShelves.map { BrunoShelfViewModel(shelf: $0) }
        await withTaskGroup(of: Void.self) { group in
            for section in newVMs {
                group.addTask { await section.load() }
            }
        }

        guard !Task.isCancelled else { return }

        let existingIDs = Set(sections.map(\.id))
        sections.append(contentsOf: newVMs.filter { $0.shouldDisplay && !existingIDs.contains($0.id) })
    }

    /// Seeded hero spotlight: a stable high-rated superset (plan §D), seed-shuffled, take 5.
    private func loadHero(seed: UInt32, session: UserSession) async -> [BaseItemDto] {
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
            return Array(BrunoRNG.shuffled(items, seed: seed).prefix(5))
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
