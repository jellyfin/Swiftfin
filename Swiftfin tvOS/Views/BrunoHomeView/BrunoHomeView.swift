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
            BrunoAmbientBackground(item: spotlightItem)
                .animation(.easeInOut(duration: 0.6), value: spotlightItem?.id)

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
    }

    private var content: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 36) {
                    header
                        .padding(.horizontal, 50)
                        .padding(.top, 20)
                        .id("bruno-top")

                    BrunoHeroView(items: viewModel.heroItems, index: $spotlightIndex)

                    ForEach(viewModel.sections) { section in
                        BrunoShelfView(viewModel: section)
                    }

                    Color.clear
                        .frame(height: 1)
                        .onAppear { viewModel.send(.appendExplore) }
                }
                .padding(.bottom, 60)
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
        }
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
