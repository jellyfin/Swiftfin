//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct GuideProgramsMenu: View {

    let programs: [BaseItemDto]
    let width: CGFloat
    let height: CGFloat
    let now: Date
    let playsOnSelect: Bool
    let accentColor: Color
    let action: (BaseItemDto) -> Void

    private var isCurrent: Bool {
        programs.contains(where: isCurrent)
    }

    private func isCurrent(_ program: BaseItemDto) -> Bool {
        guard let start = program.startDate, let end = program.endDate else { return false }
        return (start ... end).contains(now)
    }

    var body: some View {
        Menu {
            ForEach(programs, id: \.id) { program in
                Button {
                    action(program)
                } label: {
                    Text(menuLabel(for: program))
                }
                .disabled(playsOnSelect && !isCurrent(program))
            }
        } label: {
            Content(
                count: programs.count,
                start: programs.first?.startDate,
                isCurrent: isCurrent,
                accentColor: accentColor
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

extension GuideProgramsMenu {

    private struct Content: View {

        @Environment(\.isFocused)
        private var isFocused

        let count: Int
        let start: Date?
        let isCurrent: Bool
        let accentColor: Color

        private var cellPadding: CGFloat {
            guard UIDevice.isTV else { return 2 }
            return isFocused ? 0 : 4
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
            .backport
            .glassEffect(
                .regular
                    .tint(isCurrent ? accentColor.opacity(0.5) : nil)
                    .interactive(false),
                in: .rect(cornerRadius: 6)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isFocused ? accentColor : Color.secondarySystemFill.opacity(0.5),
                        lineWidth: isFocused ? 4 : 1
                    )
            }
            .padding(cellPadding)
            .animation(.easeOut(duration: 0.15), value: isFocused)
        }
    }
}
