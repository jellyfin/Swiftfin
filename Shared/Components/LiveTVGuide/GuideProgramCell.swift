//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct GuideProgramCell: View {

    private let layout = LiveTVGuideLayout()

    let entry: LiveTVGuideProgram
    let width: CGFloat
    let now: Date
    let onSelect: (BaseItemDto) -> Void

    private var programs: [BaseItemDto] {
        entry.programs
    }

    private var isCurrent: Bool {
        entry.isAiring(at: now)
    }

    private func menuLabel(for program: BaseItemDto) -> String {
        guard let start = program.startDate else { return program.displayTitle }
        return "\(start.formatted(date: .omitted, time: .shortened)) · \(program.displayTitle)"
    }

    var body: some View {
        ConditionalMenu(isMenu: entry.isGroup) {
            guard let program = programs.first else { return }
            onSelect(program)
        } menuContent: {
            ForEach(programs, id: \.id) { program in
                Button {
                    onSelect(program)
                } label: {
                    Text(menuLabel(for: program))
                }
            }
        } label: {
            Content(
                entry: entry,
                isCurrent: isCurrent,
                showsText: width >= 70,
                width: width
            )
            .frame(width: width, height: layout.rowHeight)
        }
        .buttonStyle(GuideButtonStyle())
        #if os(tvOS)
            .focusEffectDisabled()
        #endif
    }
}

extension GuideProgramCell {

    private struct Content: View {

        private let layout = LiveTVGuideLayout()
        @Environment(\.isFocused)
        private var isFocused

        let entry: LiveTVGuideProgram
        let isCurrent: Bool
        let showsText: Bool
        let width: CGFloat

        private var cellPadding: CGFloat {
            guard UIDevice.isTV else { return 2 }
            return isFocused ? 0 : 4
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                if showsText {
                    label
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.tint)
                        .opacity(0.5)
                }
            }
            .backport
            .glassEffect(
                .regular.interactive(false),
                in: .rect(cornerRadius: 6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isFocused ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.secondarySystemFill.opacity(0.5)),
                        lineWidth: isFocused ? 4 : 1
                    )
            }
            .padding(cellPadding)
            .animation(.easeOut(duration: 0.1), value: isFocused)
        }

        @ViewBuilder
        private var label: some View {
            if entry.isGroup {
                groupLabel(count: entry.programs.count, start: entry.start)
            } else if let program = entry.programs.first {
                singleLabel(program)
            }
        }

        @ViewBuilder
        private func singleLabel(_ program: BaseItemDto) -> some View {
            let text = VStack(alignment: .leading, spacing: 2) {
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

            if #available(iOS 17, tvOS 17, *), width >= 200 {
                let leadingEdge = layout.channelColumnWidth
                let maxShift = max(0, width - 76)

                text
                    .visualEffect { text, proxy in
                        text.offset(
                            x: clamp(leadingEdge + 8 - proxy.frame(in: .global).minX, min: 0, max: maxShift)
                        )
                    }
            } else {
                text
            }
        }

        @ViewBuilder
        private func groupLabel(count: Int, start: Date) -> some View {
            HStack(spacing: 4) {
                // swiftlint:disable:next hard_coded_display_string
                Text("\(count) \(L10n.programs)")
                    .font(.footnote)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(.primary)

            Text(start, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
