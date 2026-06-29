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

struct GuideProgramButton: View {

    @Default(.accentColor)
    private var accentColor

    let segment: GuideSegment
    let width: CGFloat
    let height: CGFloat
    let now: Date
    let action: (BaseItemDto) -> Void

    private var isCurrent: Bool {
        segment.isCurrent(at: now)
    }

    var body: some View {
        Group {
            if segment.isGroup {
                Menu {
                    ForEach(segment.programs, id: \.self) { program in
                        Button {
                            action(program)
                        } label: {
                            menuLabel(for: program)
                        }
                    }
                } label: {
                    Content(
                        segment: segment,
                        isCurrent: isCurrent,
                        accentColor: accentColor
                    )
                }
                .menuStyle(.button)
                .buttonStyle(GuideButtonStyle())
            } else if let program = segment.programs.first {
                Button {
                    action(program)
                } label: {
                    Content(
                        segment: segment,
                        isCurrent: isCurrent,
                        accentColor: accentColor
                    )
                }
                .buttonStyle(GuideButtonStyle())
            }
        }
        .frame(width: width, height: height)
    }

    private func menuLabel(for program: BaseItemDto) -> Text {
        if let startDate = program.startDate {
            Text(startDate, style: .time) + Text(verbatim: "  ") + Text(program.displayTitle)
        } else {
            Text(program.displayTitle)
        }
    }
}

struct GuideButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension GuideProgramButton {

    private struct Content: View {

        @Environment(\.isFocused)
        private var isFocused

        let segment: GuideSegment
        let isCurrent: Bool
        let accentColor: Color

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
                    Text(segment.programs.first?.displayTitle ?? .emptyDash)
                        .font(.footnote.weight(isCurrent ? .semibold : .regular))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if segment.isGroup {
                        Image(systemName: "ellipsis.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let startDate = segment.programs.first?.startDate {
                    Text(startDate, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(fill)
            .overlay(alignment: .leading) {
                if isCurrent {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isFocused ? accentColor : Color.secondarySystemFill.opacity(0.5),
                        lineWidth: isFocused ? 4 : 1
                    )
            }
            .padding(4)
        }
    }
}
