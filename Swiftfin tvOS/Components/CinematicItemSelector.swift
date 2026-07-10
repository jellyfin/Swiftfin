//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI

struct CinematicItemSelector<Item: Poster>: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @FocusState
    private var isHeroFocused: Bool

    @State
    private var selectedIndex = 0

    @State
    private var slideStartedAt = Date.now

    @Default(.accentColor)
    private var accentColor

    private var topContent: (Item) -> any View
    private var itemContent: (Item) -> any View
    private let action: (Item) -> Void

    let items: [Item]

    private let slideDuration: TimeInterval = 7

    private var heroItems: [Item] {
        Array(items.prefix(8))
    }

    private var normalizedSelectedIndex: Int {
        guard heroItems.isNotEmpty else { return 0 }
        return min(max(selectedIndex, 0), heroItems.count - 1)
    }

    private var selectedItem: Item? {
        heroItems[safe: normalizedSelectedIndex]
    }

    private var shouldAutoAdvance: Bool {
        heroItems.count > 1 && !reduceMotion
    }

    var body: some View {
        Group {
            if let selectedItem {
                heroView(for: selectedItem)
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            updateSelection(index: selectedIndex)
        }
        .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { date in
            guard shouldAutoAdvance,
                  date.timeIntervalSince(slideStartedAt) >= slideDuration else { return }

            moveSelection(by: 1)
        }
        .onChange(of: items) { _, newItems in
            guard newItems.isNotEmpty else {
                selectedIndex = 0
                return
            }

            updateSelection(index: min(selectedIndex, heroItems.count - 1))
        }
        .focusSection()
    }

    private func heroView(for item: Item) -> some View {
        Button {
            action(item)
        } label: {
            ZStack(alignment: .bottom) {
                heroBackdrop(for: item)

                HStack(alignment: .bottom) {
                    heroInformation(for: item)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 100)

                if heroItems.count > 1 {
                    heroPageIndicator
                        .padding(.bottom, 52)
                }
            }
            .id(item.hashValue)
            .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.985)))
            .frame(maxWidth: .infinity)
            .frame(height: 780)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .focused($isHeroFocused)
        .onMoveCommand { direction in
            switch direction {
            case .left:
                manuallyMoveSelection(by: -1)
            case .right:
                manuallyMoveSelection(by: 1)
            default:
                break
            }
        }
        .accessibilityLabel(item.displayTitle)
        .accessibilityValue(Text(verbatim: "\(normalizedSelectedIndex + 1) of \(heroItems.count)"))
        .focusEffectDisabled()
    }

    private func heroBackdrop(for item: Item) -> some View {
        ImageView(item.landscapeImageSources(environment: .default))
            .image { image in
                item.transform(image: image, displayType: .landscape)
            }
            .placeholder { _ in
                Color.black
            }
            .failure {
                Color.black
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .overlay {
                LinearGradient(
                    colors: [.black.opacity(0.72), .black.opacity(0.24), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .overlay {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.16), .black.opacity(0.94)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .allowsHitTesting(false)
    }

    private func heroInformation(for item: Item) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            topContent(item)
                .eraseToAnyView()
                .frame(width: 520, height: 120, alignment: .bottomLeading)

            heroMetadata(for: item)

            itemContent(item)
                .eraseToAnyView()
                .font(.callout)
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)

            if let overview = (item as? BaseItemDto)?.overview, overview.isNotEmpty {
                Text(overview)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
                    .frame(maxWidth: 760, alignment: .leading)
            }
        }
        .frame(maxWidth: 720, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .scaleEffect(isHeroFocused ? 1.015 : 1, anchor: .bottomLeading)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isHeroFocused)
        .shadow(color: .black.opacity(0.85), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func heroMetadata(for item: Item) -> some View {
        if let item = item as? BaseItemDto {
            let values = [
                item.productionYear.map(String.init),
                item.officialRating,
                item.runTimeLabel,
            ]
                .compactMap(\.self)
                .filter(\.isNotEmpty)

            if values.isNotEmpty {
                DotHStack {
                    ForEach(values, id: \.self) { value in
                        Text(value)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.84))
            }
        }
    }

    private var heroPageIndicator: some View {
        TimelineView(.animation) { timeline in
            HStack(spacing: 10) {
                ForEach(heroItems.indices, id: \.self) { index in
                    HeroProgressDot(
                        isActive: index == normalizedSelectedIndex,
                        progress: index == normalizedSelectedIndex ? indicatorProgress(at: timeline.date) : 0,
                        tint: accentColor
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.38), in: Capsule())
            .accessibilityHidden(true)
        }
    }

    private func indicatorProgress(at date: Date) -> CGFloat {
        guard shouldAutoAdvance else { return 0 }
        return min(max(date.timeIntervalSince(slideStartedAt) / slideDuration, 0), 1)
    }

    private func manuallyMoveSelection(by offset: Int) {
        moveSelection(by: offset)
    }

    private func moveSelection(by offset: Int) {
        guard heroItems.count > 1 else { return }
        updateSelection(index: (normalizedSelectedIndex + offset + heroItems.count) % heroItems.count)
    }

    private func updateSelection(index: Int) {
        guard heroItems.isNotEmpty else { return }

        let nextIndex = min(max(index, 0), heroItems.count - 1)

        if nextIndex != selectedIndex {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                selectedIndex = nextIndex
            }
        }

        slideStartedAt = .now
    }
}

private struct HeroProgressDot: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    let isActive: Bool
    let progress: CGFloat
    let tint: Color

    private var width: CGFloat {
        isActive ? 54 : 9
    }

    var body: some View {
        Capsule()
            .fill(.white.opacity(isActive ? 0.26 : 0.34))
            .frame(width: width, height: 9)
            .overlay(alignment: .leading) {
                if isActive {
                    Capsule()
                        .fill(tint)
                        .frame(width: width * progress)
                }
            }
            .clipShape(Capsule())
            .animation(
                reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.82),
                value: isActive
            )
    }
}

extension CinematicItemSelector {

    init(items: [Item], action: @escaping (Item) -> Void = { _ in }) {
        self.init(
            topContent: { _ in EmptyView() },
            itemContent: { _ in EmptyView() },
            action: action,
            items: items
        )
    }
}

extension CinematicItemSelector {

    func topContent(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.topContent, with: content)
    }

    func content(@ViewBuilder _ content: @escaping (Item) -> any View) -> Self {
        copy(modifying: \.itemContent, with: content)
    }
}
