//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import SwiftUI

// TODO: trailing content refactor?

struct PosterHStack<Element: Poster, Data: Collection>: View where Data.Element == Element, Data.Index == Int {

    private enum ShelfLook {
        static let cornerRadius: CGFloat = 34
        static let horizontalPadding: CGFloat = EdgeInsets.edgePadding

        static var sectionGradient: LinearGradient {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.06),
                    Color.black.opacity(0.16),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var data: Data
    private var title: String?
    private var type: PosterDisplayType
    private var label: (Element) -> any View
    private var trailingContent: () -> any View
    private var action: (Element) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            if let title {
                HStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.57, blue: 0.20),
                                    Color(red: 0.31, green: 0.74, blue: 0.94),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 10, height: 36)

                    Text(title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .textCase(.uppercase)
                        .tracking(1.1)
                        .accessibility(addTraits: [.isHeader])

                    Spacer()
                }
                .padding(.horizontal, ShelfLook.horizontalPadding)
            }

            CollectionHStack(
                uniqueElements: data,
                columns: type == .landscape ? 4 : 7
            ) { item in
                PosterButton(
                    item: item,
                    type: type
                ) {
                    action(item)
                } label: {
                    label(item).eraseToAnyView()
                }
            }
            .clipsToBounds(false)
            .dataPrefix(20)
            .insets(horizontal: EdgeInsets.edgePadding, vertical: 20)
            .itemSpacing(EdgeInsets.edgePadding - 20)
            .scrollBehavior(.continuousLeadingEdge)
        }
        .padding(.vertical, 22)
        .background {
            RoundedRectangle(cornerRadius: ShelfLook.cornerRadius, style: .continuous)
                .fill(ShelfLook.sectionGradient)
                .overlay {
                    RoundedRectangle(cornerRadius: ShelfLook.cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
                .padding(.horizontal, ShelfLook.horizontalPadding)
        }
        .focusSection()
    }
}

extension PosterHStack {

    init(
        title: String? = nil,
        type: PosterDisplayType,
        items: Data,
        action: @escaping (Element) -> Void,
        @ViewBuilder label: @escaping (Element) -> any View = { PosterButton<Element>.TitleSubtitleContentView(item: $0) }
    ) {
        self.init(
            data: items,
            title: title,
            type: type,
            label: label,
            trailingContent: { EmptyView() },
            action: action
        )
    }

    func trailing(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.trailingContent, with: content)
    }
}
