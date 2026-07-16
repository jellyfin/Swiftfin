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

    private var edge: HorizontalEdge {
        orientation.edge ?? .trailing
    }

    @FocusState
    private var focusedLetter: ItemLetter?

    @State
    private var letterSize: CGSize = .zero
    @State
    private var barHeight: CGFloat = 0
    @State
    private var activeLetter: ItemLetter?

    private let letters = ItemLetter.allCases
    private let rowHeight: CGFloat = 16

    private enum IndexEntry: Hashable {
        case letter(ItemLetter)
        case dot
    }

    static var font: Font {
        UIDevice.isTV ? .system(size: 22, weight: .semibold) : .headline
    }

    // Largest letter +1p on either side
    private var dimension: CGFloat {
        max(letterSize.width, letterSize.height) + 2
    }

    private var buttonSpacing: CGFloat {
        UIDevice.isTV ? dimension * 0.1 : 0
    }

    private var selectedLetter: ItemLetter? {
        viewModel.currentFilters.letter.first
    }

    private func letter(atY y: CGFloat) -> ItemLetter? {
        guard barHeight > 0, !letters.isEmpty else { return nil }
        let rows = displayEntries(forHeight: barHeight).count
        let contentHeight = CGFloat(rows) * rowHeight
        let inset = max(0, (barHeight - contentHeight) / 2)
        let clamped = min(max(y - inset, 0), contentHeight - 1)
        let index = Int(clamped / contentHeight * CGFloat(letters.count))
        return letters[min(max(index, 0), letters.count - 1)]
    }

    private func displayEntries(forHeight height: CGFloat) -> [IndexEntry] {
        guard height > 0, !letters.isEmpty else {
            return letters.map { .letter($0) }
        }

        let maxRows = max(1, Int(height / rowHeight))

        guard letters.count > maxRows else {
            return letters.map { .letter($0) }
        }

        let shownLetters = max(1, (maxRows + 1) / 2)
        let rowCount = shownLetters * 2 - 1
        let denominator = max(shownLetters - 1, 1)

        return (0 ..< rowCount).map { row in
            guard row.isMultiple(of: 2) else {
                return .dot
            }

            let progress = Double(row / 2) / Double(denominator)
            let index = Int((progress * Double(letters.count - 1)).rounded())
            return .letter(letters[min(max(index, 0), letters.count - 1)])
        }
    }

    var iOSView: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ForEach(Array(displayEntries(forHeight: proxy.size.height).enumerated()), id: \.offset) { _, entry in
                    Group {
                        switch entry {
                        case let .letter(letter):
                            LetterPickerButton(letter: letter, viewModel: viewModel)
                                .isSelected(selectedLetter == letter)
                                .allowsHitTesting(false)
                        case .dot:
                            Circle()
                                .fill(accentColor.opacity(0.5))
                                .frame(width: 3, height: 3)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard let letter = letter(atY: value.location.y) else { return }
                        if letter != activeLetter {
                            activeLetter = letter
                            UIDevice.impact(.light)
                        }
                    }
                    .onEnded { value in
                        let moved = abs(value.translation.height) > 4
                        let target = letter(atY: value.location.y)
                        if !moved, let target, selectedLetter == target {
                            viewModel.currentFilters.letter = []
                        } else if let target {
                            viewModel.currentFilters.letter = [target]
                        }
                        activeLetter = nil
                    }
            )
            .onAppear {
                barHeight = proxy.size.height
            }
            .onChange(of: proxy.size.height) { newValue in
                barHeight = newValue
            }
        }
        .frame(width: 18)
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
        VStack(alignment: .center, spacing: buttonSpacing) {
            ForEach(ItemLetter.allCases, id: \.hashValue) { filterLetter in
                LetterPickerButton(letter: filterLetter, viewModel: viewModel)
                    .frame(width: dimension, height: dimension)
                    .focused($focusedLetter, equals: filterLetter)
                    .isSelected(viewModel.currentFilters.letter.contains(filterLetter))
            }
        }
        .scrollIfLargerThanContainer()
        .frame(width: dimension)
        .focusSection()
        .background {
            ZStack {
                ForEach(ItemLetter.allCases, id: \.hashValue) { letter in
                    Text(letter.value)
                        .font(LetterPickerBar.font)
                }
            }
            .hidden()
            .allowsHitTesting(false)
            .fixedSize()
            .trackingSize($letterSize)
        }
        .backport
        .defaultFocus(
            $focusedLetter,
            viewModel.currentFilters.letter.first
                ?? ItemLetter.allCases.first
                ?? ItemLetter(stringLiteral: "#"),
            priority: focusedLetter == nil ? .userInitiated : .automatic
        )
        .offset(x: edge == .leading ? -EdgeInsets.edgePadding / 1.5 : EdgeInsets.edgePadding / 1.5)
        .focusSection()
    }
}

struct LetterPickerActiveLetterKey: PreferenceKey {

    static var defaultValue: ItemLetter?

    static func reduce(value: inout ItemLetter?, nextValue: () -> ItemLetter?) {
        value = nextValue() ?? value
    }
}

struct LetterPickerCallout: View {

    @Default(.accentColor)
    private var accentColor

    @State
    private var letterSize: CGSize = .zero

    let letter: ItemLetter

    var body: some View {
        Text(letter.value)
            .font(.system(size: 64, weight: .bold, design: .rounded))
            .foregroundStyle(accentColor)
            .fixedSize()
            .trackingSize($letterSize)
            .frame(
                width: max(letterSize.width, letterSize.height, 64) * 1.5,
                height: max(letterSize.width, letterSize.height, 64) * 1.5
            )
            .backport
            .glassEffect(
                .regular,
                in: .circle
            )
    }
}
