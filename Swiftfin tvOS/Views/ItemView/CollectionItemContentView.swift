//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import OrderedCollections
import SwiftUI

extension ItemView {

    struct CollectionItemContentView: View {

        typealias Element = OrderedDictionary<BaseItemKind, PagingLibraryViewModel<BaseItemDto>>.Elements.Element

        @Router
        private var router

        @ObservedObject
        var viewModel: CollectionItemViewModel

        // Actor pages: the header bumps this token when Down leaves the Favorite button; we respond by
        // imperatively focusing the first card (geometry-independent). See `GuamaFlixItemFocusBridge`.
        @EnvironmentObject
        private var focusBridge: GuamaFlixItemFocusBridge

        // First-row focus, copied directly from the movie page's `CastAndCrewHStack` (which does exactly
        // "Down from the header → first card initially, then last-focused on return; Up from below →
        // geometric"):
        //   • `firstRowFocusedCard` — every first-row poster carries this, so we always know the focused one.
        //   • `lastFocusedFirstCard` — the last first-row poster focused, restored on a return from the top.
        //   • `focusBelowFirstRow` — true while focus is in a row BELOW the first row. It makes the
        //     default-focus target nil so an Up-from-below lands GEOMETRICALLY instead of being forced.
        //   • `lowerRowsFocusedCard` — shared by every row BELOW the first, used only to set the flag above.
        // Box sets drive the landing via `.defaultFocus(…, priority: .userInitiated)` (see body), like the
        // cast row. Actor pages keep using the header→content bridge (`focusBridge`).
        @FocusState
        private var firstRowFocusedCard: AnyHashable?
        @FocusState
        private var lowerRowsFocusedCard: AnyHashable?
        @State
        private var lastFocusedFirstCard: AnyHashable?
        @State
        private var focusBelowFirstRow = false

        private var isPerson: Bool {
            viewModel.item.type == .person
        }

        private var isBoxSet: Bool {
            viewModel.item.type == .boxSet
        }

        // Both actor and box-set first rows carry the first-row focus binding (so we can track/restore the
        // focused poster). Actors force focus via the bridge; box sets via `.defaultFocus` (see body).
        private var usesFirstRowFocus: Bool {
            isPerson || isBoxSet
        }

        // NOTE: the first-row leading ids used to live in two separate computed properties that each
        // re-sorted `viewModel.sections.elements` — and `.onChange(of: firstRowLeadingCardID)` forced
        // that sort to run on EVERY render (to detect changes), so the sections were sorted twice per
        // render. They're now derived ONCE in `body` from a single sort and passed to the focus
        // handlers, so the page sorts only once per render. (Their exact `AnyHashable` wrapping is
        // preserved below — actor focus matches `AnyHashable(String?)`, box-set matches `AnyHashable(String)`.)

        // MARK: - Episode Poster HStack

        private func episodeHStack(element: Element) -> some View {
            // Match PosterHStack: 6pt title-to-row gap and the home section title font.
            VStack(alignment: .leading, spacing: 6) {

                HStack {
                    Text(L10n.episodes)
                        .font(.system(size: 32, weight: .semibold))
                        .accessibility(addTraits: [.isHeader])
                        .padding(.leading, 50)

                    Spacer()
                }

                CollectionHStack(
                    uniqueElements: element.value.elements,
                    id: \.unwrappedIDHashOrZero,
                    columns: 3.5
                ) { episode in
                    SeriesEpisodeSelector.EpisodeCard(episode: episode)
                        .padding(.horizontal, 4)
                }
                .scrollBehavior(.continuousLeadingEdge)
                .insets(horizontal: EdgeInsets.edgePadding)
                .itemSpacing(EdgeInsets.edgePadding / 2)
            }
            .focusSection()
        }

        // MARK: - Default Poster HStack

        private func posterHStack(element: Element, focusBinding: FocusState<AnyHashable?>.Binding?) -> some View {
            PosterHStack(
                title: element.key.pluralDisplayTitle,
                type: .portrait,
                items: element.value.elements,
                focusedItem: focusBinding,
                action: { item in
                    router.route(to: .item(item: item))
                },
                // Movies/Shows rows (collection contents, actor filmography) show the year only —
                // same `PosterYearLabel` (format + off-white style) as the home and "More Like This".
                label: { PosterYearLabel(item: $0) }
            )
            .focusSection()

            // TODO: Is this possible?
            /* .trailing {
                 SeeMoreButton() {
                     router.route(to: .library(viewModel: element.value))
                 }
             } */
        }

        // Section order: Movies first, then Shows (series), then everything else, with Episodes
        // always last. (The default ordering sorts by the kind's raw string, which alphabetically
        // put "Episode" before "Movie" — so episodes showed first.)
        private func sectionRank(_ kind: BaseItemKind) -> Int {
            switch kind {
            case .movie: 0
            case .series: 1
            case .episode: 3
            default: 2
            }
        }

        var body: some View {
            // Sort ONCE per render and derive everything from it (previously sorted up to twice/render).
            let sortedSections = viewModel.sections.elements.sorted { sectionRank($0.key) < sectionRank($1.key) }
            // The first poster (non-episode) row — its leading card is the "Down from Favorite" target
            // on actor pages. Episodes are ranked last, so this is normally the Movies row.
            let firstPosterElement = sortedSections.first(where: { $0.key != .episode })
            let firstPosterKey = firstPosterElement?.key
            let firstLeadingCardOptionalID = firstPosterElement?.value.elements.first?.id
            // Actor "Down from Favorite" target — wraps the OPTIONAL id (matches the poster binding).
            let firstRowLeadingID = AnyHashable(firstLeadingCardOptionalID)
            // Box-set first-row default-focus target (the cast row's `defaultFocusTarget`): nil when focus
            // arrives FROM BELOW (→ engine keeps its geometric pick), else the last-focused poster (or the
            // first one before you've moved) so Down-from-Sort lands first-then-last.
            let firstRowDefaultTarget: AnyHashable? = focusBelowFirstRow
                ? nil
                : (lastFocusedFirstCard ?? firstRowLeadingID)

            // 28pt between sections, matching the home screen's section rhythm.
            VStack(spacing: 28) {
                ForEach(sortedSections, id: \.key) { element in
                    if element.key == .episode {
                        episodeHStack(element: element)
                    } else if element.key == firstPosterKey {
                        // First row carries the focus binding (track + restore). Box sets add the
                        // directional `.defaultFocus` — exactly the movie page's `CastAndCrewHStack`:
                        // Down-from-Sort → first/last (target non-nil); Up-from-below → geometric (nil).
                        posterHStack(
                            element: element,
                            focusBinding: usesFirstRowFocus ? $firstRowFocusedCard : nil
                        )
                        .if(isBoxSet) {
                            $0.defaultFocus($firstRowFocusedCard, firstRowDefaultTarget, priority: .userInitiated)
                        }
                    } else {
                        // Rows BELOW the first: box sets share one focus binding so we know when focus is
                        // below the first row (sets `focusBelowFirstRow`). Everything else is geometric.
                        posterHStack(
                            element: element,
                            focusBinding: isBoxSet ? $lowerRowsFocusedCard : nil
                        )
                    }
                }

                if viewModel.similarItems.isNotEmpty {
                    // "More Like This" is a row BELOW the first row too, so it must also flip
                    // `focusBelowFirstRow` (it doesn't use `$lowerRowsFocusedCard`, having its own focus
                    // binding). Without this, a box set whose ONLY row above it is Movies (no series/actors
                    // row in between to set the flag) would treat Up-from-here as a top entry and restore
                    // the last movie instead of landing geometrically. Box sets only; actors use the bridge.
                    // Stock `SimilarItemsHStack(items:)` — this view is dead on tvOS (GuamaFlix renders
                    // `NativeCollectionContentView`), so it doesn't need the edited focus-reporting binding.
                    ItemView.SimilarItemsHStack(
                        items: viewModel.similarItems
                    )
                }

                // Virtual collections (Favorites/Watchlist) have no real item, so no "About" section.
                if !viewModel.isVirtual {
                    ItemView.AboutView(viewModel: viewModel)
                }
            }
            // Virtual collections end on a poster row (no About section below), so add bottom breathing
            // room — matching the space the About section leaves on other detail pages.
            .padding(.bottom, viewModel.isVirtual ? 100 : 0)
            // Down from the header (actor: Favorite button; collection: the Sort/bottom button) →
            // imperatively focus the first row's remembered card (or its leading card the first time).
            // This is the ONLY thing that forces first-row focus; every other entry (Up from a lower row)
            // is left to the focus engine → geometric.
            .onChange(of: focusBridge.focusFirstRowToken) { _, _ in
                guard isPerson else { return }
                firstRowFocusedCard = lastFocusedFirstCard ?? firstRowLeadingID
            }
            // Track the last-focused first-row card (so a return from the top restores it), and note that
            // focus is now ON the first row → its default target applies again next time. (Cast row's
            // `onChange(of: focusedActor)`: remember + `focusBelowCast = false`.)
            .onChange(of: firstRowFocusedCard) { _, newValue in
                if let newValue {
                    lastFocusedFirstCard = newValue
                    focusBelowFirstRow = false
                }
            }
            // Box sets: focus moved into a row BELOW the first → the next entry into the first row should be
            // geometric (target nil). Mirrors `SimilarItemsHStack` setting `focusBelowCast = true`.
            .onChange(of: lowerRowsFocusedCard) { _, newValue in
                if newValue != nil {
                    focusBelowFirstRow = true
                }
            }
        }
    }
}
