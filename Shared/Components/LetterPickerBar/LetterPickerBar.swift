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

    private enum Row: Hashable {
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

    private var rows: [Row] {
        guard barHeight > 0,
              letters.count > 21,
              CGFloat(letters.count) * dimension > barHeight
        else { return letters.map { .letter($0) } }

        let selectedIndex = selectedLetter.flatMap { letters.firstIndex(of: $0) }
        let landmarks = (0 ... 10).map { Int((Double($0) / 10 * Double(letters.count - 1)).rounded()) }

        return zip(landmarks, landmarks.dropFirst()).flatMap { lower, upper -> [Row] in
            if let selectedIndex, selectedIndex > lower, selectedIndex < upper {
                [.letter(letters[lower]), .letter(letters[selectedIndex])]
            } else {
                [.letter(letters[lower]), .dot]
            }
        } + [.letter(letters[letters.count - 1])]
    }

    private var contentHeight: CGFloat {
        min(CGFloat(rows.count) * dimension, barHeight)
    }

    private var contentInset: CGFloat {
        max(0, (barHeight - contentHeight) / 2)
    }

    private func letter(atY y: CGFloat) -> ItemLetter? {
        guard barHeight > 0, !letters.isEmpty else { return nil }
        let clamped = min(max(y - contentInset, 0), contentHeight - 1)
        let index = Int(clamped / contentHeight * CGFloat(letters.count))
        return letters[min(max(index, 0), letters.count - 1)]
    }

    private func row(atY y: CGFloat) -> Row? {
        let localY = y - contentInset
        guard barHeight > 0, localY >= 0, localY < contentHeight else { return nil }
        let index = Int(localY / dimension)
        return rows.indices.contains(index) ? rows[index] : nil
    }

    private func toggleLetter(_ letter: ItemLetter) {
        if viewModel.currentFilters.letter.contains(letter) {
            viewModel.currentFilters.letter = []
        } else {
            viewModel.currentFilters.letter = [letter]
        }
    }

    private var letterBar: some View {
        VStack(spacing: UIDevice.isTV ? dimension * 0.1 : 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                switch row {
                case let .letter(letter):
                    LetterPickerButton(letter) {
                        toggleLetter(letter)
                    }
                    .isSelected(selectedLetter == letter)
                    .frame(width: dimension, height: dimension)
                    .focused($focusedLetter, equals: letter)
                    .allowsHitTesting(UIDevice.isTV)
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
                ForEach(letters, id: \.hashValue) { letter in
                    Text(letter.value)
                }
            }
            .hidden()
            .fixedSize()
            .trackingSize($letterSize)
        }
        .font(UIDevice.isTV ? .system(size: 22, weight: .semibold) : .footnote)
    }

    var iOSView: some View {
        letterBar
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                #if os(iOS)
                GestureView()
                    .environment(\.panGestureDirection, .vertical)
                    .environment(\.panAction, PanAction { _, _, location, _, state in
                        switch state {
                        case .began, .changed:
                            guard let target = letter(atY: location.y), target != activeLetter else { return }
                            activeLetter = target
                            UIDevice.impact(.light)
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
                        case let .letter(letter)?:
                            toggleLetter(letter)
                        case .dot?:
                            viewModel.currentFilters.letter = []
                        case nil:
                            break
                        }
                    })
                #endif
            }
            .onSizeChanged { size, _ in
                barHeight = size.height
            }
            .frame(width: dimension)
            .padding(.vertical, EdgeInsets.edgePadding / 2)
            .padding(.horizontal, 0)
            .offset(x: orientation == .leading ? EdgeInsets.edgePadding / 2 : -EdgeInsets.edgePadding / 2)
            .preference(key: PresentationControllerShouldDismissPreferenceKey.self, value: activeLetter == nil)
            .preference(key: LetterPickerActiveLetterKey.self, value: activeLetter)
    }

    var tvOSView: some View {
        letterBar
            .scrollIfLargerThanContainer()
            .frame(width: dimension)
            .focusSection()
            .backport
            .defaultFocus(
                $focusedLetter,
                selectedLetter ?? letters.first ?? "#",
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
            .preference(key: LetterPickerActiveLetterKey.self, value: activeLetter)
    }
}
