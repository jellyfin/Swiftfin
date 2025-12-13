//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct OverviewView: View {

        #if !os(tvOS)
        @Router
        private var router
        #endif

        let item: BaseItemDto

        private var overviewLineLimit: Int?
        private var taglineLineLimit: Int?

        // MARK: - Body

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                personMetadata

                if let firstTagline = item.taglines?.first {
                    Text(firstTagline)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .lineLimit(taglineLineLimit)
                }

                overviewText
            }
            .font(.footnote)
            .labeledContentStyle(.itemAttribute)
        }

        // MARK: - Person Metadata

        @ViewBuilder
        private var personMetadata: some View {
            let hasPersonData = item.birthday != nil || item.deathday != nil || item.birthplace != nil

            if hasPersonData {
                FlowLayout(spacing: UIDevice.isPhone ? 20 : 50) {
                    if let birthday = item.birthday?.formatted(date: .long, time: .omitted) {
                        LabeledContent(L10n.born, value: birthday)
                    }

                    if let deathday = item.deathday?.formatted(date: .long, time: .omitted) {
                        LabeledContent(L10n.died, value: deathday)
                    }

                    if let birthplace = item.birthplace, birthplace.isNotEmpty {
                        LabeledContent(L10n.birthplace, value: birthplace)
                    }
                }
            }
        }

        // MARK: - Overview Text

        @ViewBuilder
        private var overviewText: some View {
            if let itemOverview = item.overview {
                #if os(tvOS)
                Text(itemOverview)
                    .font(.subheadline)
                    .lineLimit(overviewLineLimit)
                #else
                TruncatedText(itemOverview)
                    .onSeeMore {
                        router.route(to: .itemOverview(item: item))
                    }
                    .seeMoreType(.view)
                    .lineLimit(overviewLineLimit)
                #endif
            }
        }
    }
}

// MARK: - Modifiers

extension ItemView.OverviewView {

    init(item: BaseItemDto) {
        self.init(
            item: item,
            overviewLineLimit: nil,
            taglineLineLimit: nil
        )
    }

    func overviewLineLimit(_ limit: Int) -> Self {
        copy(modifying: \.overviewLineLimit, with: limit)
    }

    func taglineLineLimit(_ limit: Int) -> Self {
        copy(modifying: \.taglineLineLimit, with: limit)
    }
}
