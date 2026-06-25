//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoHomeView (tvOS only)

//
// The Bruno home tab: BRUNO wordmark + Shuffle, a seeded hero, then the seeded shelf spine
// and explore tail (plan §C1/§C5). Hero + cards route to the stock detail/player (unmodified).
// A bottom sentinel grows the explore tail on scroll; Shuffle re-rolls the seed.
struct BrunoHomeView: View {

    @StateObject
    private var viewModel = BrunoHomeViewModel()

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    /// Selected hero spotlight, shared with the ambient backdrop so it tracks the feature.
    @State
    private var spotlightIndex = 0

    private var spotlightItem: BaseItemDto? {
        viewModel.heroItems[safe: spotlightIndex] ?? viewModel.heroItems.first
    }

    var body: some View {
        ZStack {
            // One fixed backdrop (the first spotlight), not the cycling one — keeps the home
            // snappy by never re-blurring a full-res cover as the hero rotates or you scroll.
            BrunoAmbientBackground(item: viewModel.heroItems.first)

            if viewModel.sections.isNotEmpty || !viewModel.heroItems.isEmpty {
                content
            } else {
                switch viewModel.state {
                case let .error(error):
                    errorView(error)
                default:
                    ProgressView()
                        .scaleEffect(2)
                        .tint(Color.bruno.accent)
                }
            }
        }
        .ignoresSafeArea()
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .onAppear {
            // Re-entry (tab switch back) or returning from playback re-fires onAppear but not
            // onFirstAppear: re-pick the hero so the banner is fresh on every entry. Skipped on the
            // very first appearance (hero still empty → the initial refresh seeds it).
            if !viewModel.heroItems.isEmpty {
                spotlightIndex = 0
                viewModel.send(.reshuffleHero)
            }
        }
    }

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 36) {
                    BrunoHeroView(
                        items: viewModel.heroItems,
                        index: $spotlightIndex,
                        bleedsTop: true,
                        // Taller banner: restores the vacated wordmark-row space AND shows more of the
                        // backdrop (incl. its top) so the subject reads centered below the nav.
                        extraHeight: 200,
                        autoAdvanceEnabled: viewModel.state == .content
                    )
                    // BRUNO wordmark floats ON TOP of the hero (z-order), at the same title-safe
                    // top-left spot it held as a row — the banner now extends up under it. The overlay
                    // aligns to the hero's layout box (still title-safe), so the original 50/20 insets
                    // place it exactly where it was; no overscan compensation needed.
                    .overlay(alignment: .top) {
                            header
                                .padding(.horizontal, 50)
                                .padding(.top, 20)
                        }
                        .id("bruno-top")

                    ForEach(viewModel.sections) { section in
                        BrunoShelfView(viewModel: section)
                            // INV-8/INV-9: shelves stream in top-down (the VM reveals them in plan
                            // order); each rises into place with a soft fade + 16pt drift so the fill
                            // reads as an intentional reveal, not random pop-in. Honors reduce-motion.
                                .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 16)))
                    }

                    Color.clear
                        .frame(height: 1)
                        .onAppear { viewModel.send(.appendExplore) }
                }
                .padding(.bottom, 60)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.35), value: viewModel.sections.count)
            }
            .onChange(of: viewModel.scrollResetToken) { _, _ in
                if reduceMotion {
                    proxy.scrollTo("bruno-top", anchor: .top)
                } else {
                    withAnimation { proxy.scrollTo("bruno-top", anchor: .top) }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("BRUNO")
                .font(.brunoDisplay(40, weight: .bold))
                .tracking(6)
                .foregroundStyle(Color.bruno.fg)
            Circle()
                .fill(Color.bruno.accent)
                .frame(width: 12, height: 12)

            Spacer()

            // Build stamp: the app executable's build time. Auto-updates every build, so it's an
            // unambiguous "which build am I looking at?" marker. (Temporary diagnostic.)
            Text(Self.buildStamp)
                .font(.brunoBody(20, weight: .semibold))
                .foregroundStyle(Color.bruno.accent)
        }
    }

    private static var buildStamp: String {
        guard let executableURL = Bundle.main.executableURL,
              let attributes = try? FileManager.default.attributesOfItem(atPath: executableURL.path),
              let date = attributes[.modificationDate] as? Date
        else { return "BUILD —" }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d · HH:mm:ss"
        return "BUILD \(formatter.string(from: date))"
    }

    private func errorView(_ error: ErrorMessage) -> some View {
        VStack(spacing: 16) {
            Text("Couldn't load Bruno")
                .font(.brunoDisplay(40, weight: .semibold))
                .foregroundStyle(Color.bruno.fg)
            Text(error.localizedDescription)
                .font(.brunoBody(22))
                .foregroundStyle(Color.bruno.fgMuted)
            Button("Try Again") { viewModel.send(.refresh) }
                .buttonStyle(.card)
        }
        .padding(60)
    }
}
