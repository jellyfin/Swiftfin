//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct GuideProgramButton: View {

    let program: BaseItemDto
    let width: CGFloat
    let now: Date
    let playsOnSelect: Bool
    let action: () -> Void

    private var isCurrent: Bool {
        guard let start = program.startDate, let end = program.endDate else { return false }
        return (start ... end).contains(now)
    }

    private var isSelectable: Bool {
        !playsOnSelect || isCurrent
    }

    var body: some View {
        Button {
            guard isSelectable else { return }
            action()
        } label: {
            Content(
                program: program,
                isCurrent: isCurrent,
                showsText: width >= 70,
                width: width
            )
            .frame(width: width, height: GuideLayout.current.rowHeight)
        }
        .buttonStyle(GuideButtonStyle())
        #if os(tvOS)
            .focusEffectDisabled()
        #endif
    }
}

extension GuideProgramButton {

    private struct Content: View {

        @Environment(\.isFocused)
        private var isFocused

        let program: BaseItemDto
        let isCurrent: Bool
        let showsText: Bool
        let width: CGFloat

        private var cellPadding: CGFloat {
            guard UIDevice.isTV else { return 2 }
            return isFocused ? 0 : 4
        }

        @ViewBuilder
        private var textContent: some View {
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

        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                if showsText {
                    if #available(iOS 17, tvOS 17, *), width >= 200 {
                        let leadingEdge = GuideLayout.current.channelColumnWidth
                        let maxShift = max(0, width - 76)

                        textContent
                            .visualEffect { content, proxy in
                                content.offset(
                                    x: clamp(leadingEdge + 8 - proxy.frame(in: .global).minX, min: 0, max: maxShift)
                                )
                            }
                    } else {
                        textContent
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.foreground)
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
                        isFocused ? AnyShapeStyle(.foreground) : AnyShapeStyle(Color.secondarySystemFill.opacity(0.5)),
                        lineWidth: isFocused ? 4 : 1
                    )
            }
            .padding(cellPadding)
            .animation(.easeOut(duration: 0.1), value: isFocused)
        }
    }
}
