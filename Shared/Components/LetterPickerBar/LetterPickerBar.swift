//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LetterPickerBar: PlatformView {

    @Default(.accentColor)
    private var accentColor

    @Default(.Customization.Library.letterPickerOrientation)
    private var orientation

    @ObservedObject
    var viewModel: FilterViewModel

    @FocusState
    private var focusedLetter: ItemLetter?

    @State
    private var letterSize: CGSize = .zero
    @State
    private var barHeight: CGFloat = 0
    @State
    private var activeLetter: ItemLetter?

    private let letters = ItemLetter.allCases

    enum Row: Hashable {
        case letter(ItemLetter)
        case dot
    }

    private var edge: HorizontalEdge {
        orientation.edge ?? .trailing
    }

    private var dimension: CGFloat {
        max(letterSize.width, letterSize.height) + 2
    }

    private var selectedLetter: ItemLetter? {
        viewModel.currentFilters.letter.first
    }

    // iOS scrubs, so abbreviate to landmark letters when the full alphabet
    // can't fit; tvOS scrolls and always shows every letter.
    private var rows: [Row] {
        let isCompact = barHeight > 0
            && letters.count > 21
            && CGFloat(letters.count) * dimension > barHeight

        guard isCompact else { return letters.map { .letter($0) } }

        let selectedIndex = selectedLetter.flatMap { letters.firstIndex(of: $0) }
        let landmarks = (0 ... 10).map { Int((Double($0) / 10 * Double(letters.count - 1)).rounded()) }

        return landmarks.enumerated().flatMap { offset, index -> [Row] in
            var entries: [Row] = [.letter(letters[index])]

            if offset < landmarks.count - 1 {
                let upper = landmarks[offset + 1]
                if let selectedIndex, selectedIndex > index, selectedIndex < upper {
                    entries.append(.letter(letters[selectedIndex]))
                } else {
                    entries.append(.dot)
                }
            }

            return entries
        }
    }

    private func letter(atY y: CGFloat) -> ItemLetter? {
        guard barHeight > 0, !letters.isEmpty else { return nil }
        let contentHeight = min(CGFloat(rows.count) * dimension, barHeight)
        let inset = max(0, (barHeight - contentHeight) / 2)
        let clamped = min(max(y - inset, 0), contentHeight - 1)
        let index = Int(clamped / contentHeight * CGFloat(letters.count))
        return letters[min(max(index, 0), letters.count - 1)]
    }

    private func row(atY y: CGFloat) -> Row? {
        guard barHeight > 0, dimension > 0 else { return nil }
        let contentHeight = min(CGFloat(rows.count) * dimension, barHeight)
        let inset = max(0, (barHeight - contentHeight) / 2)
        let localY = y - inset
        guard localY >= 0, localY < contentHeight else { return nil }
        let index = Int(localY / dimension)
        return rows.indices.contains(index) ? rows[index] : nil
    }

    private var letterBar: some View {
        VStack(spacing: UIDevice.isTV ? dimension * 0.1 : 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                switch row {
                case let .letter(letter):
                    LetterPickerButton(letter) {
                        if viewModel.currentFilters.letter.contains(letter) {
                            viewModel.currentFilters.letter = []
                        } else {
                            viewModel.currentFilters.letter = [letter]
                        }
                    }
                    .isSelected(selectedLetter == letter)
                    .frame(width: dimension, height: dimension)
                    .if(UIDevice.isTV) { view in
                        view
                            .focused($focusedLetter, equals: letter)
                    }
                    .if(!UIDevice.isTV) { view in
                        view
                            .allowsHitTesting(false)
                    }
                case .dot:
                    Circle()
                        .fill(accentColor.opacity(0.5))
                        .frame(width: 3, height: 3)
                        .frame(width: dimension, height: dimension)
                }
            }
        }
        .frame(width: dimension)
        .background {
            ZStack {
                ForEach(ItemLetter.allCases, id: \.hashValue) { letter in
                    Text(letter.value)
                }
            }
            .hidden()
            .allowsHitTesting(false)
            .fixedSize()
            .trackingSize($letterSize)
        }
        .font(UIDevice.isTV ? .system(size: 22, weight: .semibold) : .footnote)
    }

    var iOSView: some View {
        GeometryReader { proxy in
            letterBar
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    #if os(iOS)
                    GestureView()
                        .environment(\.panGestureDirection, .vertical)
                        .environment(\.panAction, PanAction { _, _, location, _, state in
                            switch state {
                            case .began, .changed:
                                if let target = letter(atY: location.y), target != activeLetter {
                                    activeLetter = target
                                    UIDevice.impact(.light)
                                }
                            case .ended, .cancelled, .failed:
                                if let target = letter(atY: location.y) {
                                    viewModel.currentFilters.letter = [target]
                                }
                                activeLetter = nil
                            default:
                                break
                            }
                        })
                        .environment(\.tapGestureAction, TapAction { location, _, _ in
                            switch row(atY: location.y) {
                            case let .letter(tapped)?:
                                if selectedLetter == tapped {
                                    viewModel.currentFilters.letter = []
                                } else {
                                    viewModel.currentFilters.letter = [tapped]
                                }
                            case .dot?:
                                viewModel.currentFilters.letter = []
                            case nil:
                                break
                            }
                        })
                    #endif
                }
                .onAppear {
                    barHeight = proxy.size.height
                }
                .onChange(of: proxy.size.height) { newValue in
                    barHeight = newValue
                }
        }
        .frame(width: dimension)
        .padding(.horizontal, 2)
        .padding(.vertical, EdgeInsets.edgePadding / 2)
        .padding(edge == .leading ? .leading : .trailing, EdgeInsets.edgePadding / 2)
        .preference(
            key: PresentationControllerShouldDismissPreferenceKey.self,
            value: activeLetter == nil
        )
        .preference(
            key: LetterPickerActiveLetterKey.self,
            value: activeLetter
        )
    }

    var tvOSView: some View {
        letterBar
            .scrollIfLargerThanContainer()
            .frame(width: dimension)
            .focusSection()
            .backport
            .defaultFocus(
                $focusedLetter,
                selectedLetter ?? letters.first ?? ItemLetter(stringLiteral: "#"),
                priority: focusedLetter == nil ? .userInitiated : .automatic
            )
            .offset(x: edge == .leading ? -EdgeInsets.edgePadding / 1.5 : EdgeInsets.edgePadding / 1.5)
            .focusSection()
            .task(id: focusedLetter) {
                activeLetter = focusedLetter
                guard focusedLetter != nil else { return }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                activeLetter = nil
            }
            .preference(
                key: LetterPickerActiveLetterKey.self,
                value: activeLetter
            )
    }
}
