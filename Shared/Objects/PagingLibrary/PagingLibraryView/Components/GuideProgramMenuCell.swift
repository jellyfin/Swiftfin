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

struct GuideProgramMenuCell: View {

    let programs: [BaseItemDto]
    let width: CGFloat
    let height: CGFloat
    let now: Date
    let onSelect: (BaseItemDto) -> Void

    private var isCurrent: Bool {
        programs.contains { program in
            guard let start = program.startDate, let end = program.endDate else { return false }
            return (start ... end).contains(now)
        }
    }

    var body: some View {
        Menu {
            ForEach(programs, id: \.id) { program in
                Button {
                    onSelect(program)
                } label: {
                    Text(menuLabel(for: program))
                }
            }
        } label: {
            Content(
                count: programs.count,
                start: programs.first?.startDate,
                isCurrent: isCurrent
            )
            .frame(width: width, height: height)
        }
        #if os(tvOS)
        .menuStyle(.borderlessButton)
        .focusEffectDisabled()
        #endif
    }

    private func menuLabel(for program: BaseItemDto) -> String {
        guard let start = program.startDate else { return program.displayTitle }
        return "\(start.formatted(date: .omitted, time: .shortened)) · \(program.displayTitle)"
    }
}

extension GuideProgramMenuCell {

    private struct Content: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isFocused)
        private var isFocused

        let count: Int
        let start: Date?
        let isCurrent: Bool

        private var fill: Color {
            if isCurrent {
                return accentColor.opacity(0.5)
            }

            #if os(tvOS)
            return Color(white: 0.22)
            #else
            return Color.systemFill
            #endif
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    // swiftlint:disable:next hard_coded_display_string
                    Text("\(count) \(L10n.programs)")
                        .font(.footnote)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(Color.primary)

                if let start {
                    Text(start, style: .time)
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isFocused ? accentColor : Color.secondarySystemFill.opacity(0.5),
                        lineWidth: isFocused ? 4 : 1
                    )
            }
            .padding(2)
        }
    }
}
