//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

struct EPGProgramCell: View {

    @State
    private var stickyOffset: CGFloat

    let scrollState: EPGScrollState
    let isCurrent: Bool
    let isFocused: Bool
    let accentColor: Color
    let action: () -> Void

    private let leadingOffset: CGFloat
    private let presentation: ProgramCellPresentation

    init(
        scrollState: EPGScrollState,
        block: ProgramBlock,
        leadingOffset: CGFloat,
        isCurrent: Bool,
        isFocused: Bool,
        accentColor: Color,
        action: @escaping () -> Void
    ) {
        self.scrollState = scrollState
        self.isCurrent = isCurrent
        self.isFocused = isFocused
        self.accentColor = accentColor
        self.action = action
        self.leadingOffset = leadingOffset
        self.presentation = ProgramCellPresentation(block: block)
        self._stickyOffset = State(
            initialValue: max(0, scrollState.visibleLeadingOffset - leadingOffset)
        )
    }

    private var backgroundColor: Color {
        if isFocused {
            .white
        } else if isCurrent {
            accentColor.opacity(0.5)
        } else {
            Color.secondarySystemFill.opacity(0.5)
        }
    }

    private var primaryColor: Color {
        isFocused ? .black : .primary
    }

    private var secondaryColor: Color {
        isFocused ? .black.opacity(0.6) : .secondary
    }

    private var stickyOffsetPublisher: AnyPublisher<CGFloat, Never> {
        scrollState.visibleLeadingOffsetPublisher
            .map { max(0, $0 - leadingOffset) }
            .removeDuplicates { abs($0 - $1) <= 0.5 }
            .eraseToAnyPublisher()
    }

    var body: some View {
        Button(action: action) {
            StickyProgramContentLayout(
                stickyOffset: stickyOffset
            ) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.title)
                        .font(.footnote.weight(isCurrent ? .semibold : .regular))
                        .foregroundStyle(primaryColor)

                    Text(presentation.time)
                        .font(.caption2)
                        .foregroundStyle(secondaryColor)
                }
                .lineLimit(1)
            }
            .background(backgroundColor)
            .overlay {
                Rectangle()
                    .strokeBorder(Color.secondarySystemFill.opacity(0.5), lineWidth: isFocused ? 0 : 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(EPGButtonStyle())
        .accessibilityValue(isCurrent ? L10n.onNow : "")
        .onReceive(stickyOffsetPublisher) { stickyOffset in
            self.stickyOffset = stickyOffset
        }
    }
}

private struct ProgramCellPresentation {

    let title: String
    let time: String

    init(block: ProgramBlock) {
        if block.isGroup {
            // swiftlint:disable:next hard_coded_display_string
            self.title = "\(block.programs.count) \(L10n.programs)"
            self.time = block.start.formatted(date: .omitted, time: .shortened)
        } else if let program = block.programs.first {
            self.title = program.displayTitle
            self.time = [
                program.startDate?.formatted(date: .omitted, time: .shortened),
                program.endDate?.formatted(date: .omitted, time: .shortened),
            ]
                .compactMap(\.self)
                .joined(separator: " \(String.bullet) ")
        } else {
            self.title = L10n.programs
            self.time = ""
        }
    }
}

private struct StickyProgramContentLayout: Layout {

    let stickyOffset: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard let content = subviews.first else { return }

        let contentSize = content.sizeThatFits(.unspecified)
        let horizontalPadding: CGFloat = 8
        let maximumShift = max(0, bounds.width - contentSize.width - horizontalPadding * 2)
        let shift = clamp(
            stickyOffset,
            min: 0,
            max: maximumShift
        )

        content.place(
            at: CGPoint(
                x: bounds.minX + horizontalPadding + shift,
                y: bounds.minY + 6
            ),
            anchor: .topLeading,
            proposal: ProposedViewSize(
                width: min(
                    contentSize.width,
                    max(0, bounds.width - horizontalPadding * 2 - shift)
                ),
                height: contentSize.height
            )
        )
    }
}
