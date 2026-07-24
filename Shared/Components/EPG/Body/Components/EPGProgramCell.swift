//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct EPGProgramCell: View {

    private let layout = EPGLayout()

    let block: ProgramBlock
    let now: Date
    let action: (BaseItemDto) -> Void

    private func menuTitle(for program: BaseItemDto) -> String {
        guard let start = program.startDate else { return program.displayTitle }
        return "\(start.formatted(date: .omitted, time: .shortened)) · \(program.displayTitle)"
    }

    var body: some View {
        ConditionalMenu(isMenu: block.isGroup) {
            guard let program = block.programs.first else { return }
            action(program)
        } menuContent: {
            ForEach(block.programs, id: \.id) { program in
                Button(menuTitle(for: program)) {
                    action(program)
                }
            }
        } label: {
            Content(
                block: block,
                isCurrent: block.isAiring(at: now)
            )
            .frame(width: block.width, height: layout.rowHeight)
        }
        .buttonStyle(EPGButtonStyle())
    }
}

extension EPGProgramCell {

    private struct Content: View {

        @Default(.Customization.EPG.programColorSelection)
        private var selectedTypes
        @Default(.Customization.EPG.programColor)
        private var typeColors

        @Environment(\.isFocused)
        private var isFocused

        private let layout = EPGLayout()

        let block: ProgramBlock
        let isCurrent: Bool

        private var typeColor: Color? {
            guard let program = block.programs.first else { return nil }

            return ProgramType.allCases
                .first { selectedTypes.contains($0) && $0.matches(program) }
                .map { typeColors[$0] ?? $0.color }
        }

        private var backgroundStyle: AnyShapeStyle {
            if isCurrent {
                AnyShapeStyle(.tint.opacity(0.5))
            } else if let typeColor {
                AnyShapeStyle(typeColor.opacity(0.35))
            } else {
                AnyShapeStyle(Color.secondarySystemFill.opacity(0.5))
            }
        }

        private var borderStyle: AnyShapeStyle {
            isFocused ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.secondarySystemFill.opacity(0.5))
        }

        private var cellPadding: CGFloat {
            guard UIDevice.isTV else { return 2 }
            return isFocused ? 0 : 4
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                if block.width >= 70 {
                    label
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundStyle)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(borderStyle, lineWidth: isFocused ? 4 : 1)
            }
            .padding(cellPadding)
            .animation(.easeOut(duration: 0.1), value: isFocused)
        }

        @ViewBuilder
        private var label: some View {
            if block.isGroup {
                groupLabel
            } else if let program = block.programs.first {
                programLabel(for: program)
            }
        }

        @ViewBuilder
        private var groupLabel: some View {
            // swiftlint:disable:next hard_coded_display_string
            Label("\(block.programs.count) \(L10n.programs)", systemImage: "chevron.down")
                .font(.footnote)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Text(block.start, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }

        @ViewBuilder
        private func programLabel(for program: BaseItemDto) -> some View {
            if #available(iOS 17, *), block.width >= 200 {
                let leadingEdge = layout.channelColumnWidth
                let cellWidth = block.width

                programText(for: program)
                    .visualEffect { content, proxy in
                        content.offset(
                            x: clamp(
                                leadingEdge + 8 - proxy.frame(in: .global).minX,
                                min: 0,
                                max: max(0, cellWidth - proxy.size.width - 16)
                            )
                        )
                    }
            } else {
                programText(for: program)
            }
        }

        private func programText(for program: BaseItemDto) -> some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(program.displayTitle)
                    .font(.footnote.weight(isCurrent ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                DotHStack {
                    if let startDate = program.startDate {
                        Text(startDate, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let endDate = program.endDate {
                        Text(endDate, style: .time)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
