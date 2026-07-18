//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct AboutItemGroup: ContentGroup {

    let displayTitle: String
    let id: String
    let item: BaseItemDto

    func body(with viewModel: Empty) -> Body {
        Body(item: item)
    }

    struct Body: View {

        @Router
        private var router

        let item: BaseItemDto

        private struct AboutCard<Content: View>: View {

            let title: String
            let subtitle: String?
            let action: () -> Void
            let content: Content

            init(
                title: String,
                subtitle: String? = nil,
                action: @escaping () -> Void,
                @ViewBuilder content: () -> Content
            ) {
                self.title = title
                self.subtitle = subtitle
                self.action = action
                self.content = content()
            }

            var body: some View {
                Button(action: action) {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .topLeading)

                            if let subtitle, subtitle.isNotEmpty {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .topLeading)

                        content
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .backport
                    .glassEffect(
                        in: .rect(
                            cornerRadius: 20,
                            style: .continuous
                        )
                    )
                }
                .foregroundStyle(.primary, .secondary)
                .buttonStyle(.card)
                .buttonBorderShape(.roundedRectangle(radius: 20))
            }
        }

        @ViewBuilder
        private var descriptionCard: some View {
            let subtitle = item.taglines?.first ?? item.parentTitle

            AboutCard(
                title: item.displayTitle,
                subtitle: subtitle
            ) {
                router.route(to: .itemOverview(item: item))
            } content: {
                if let overview = item.overview, overview.isNotEmpty {
                    SeeMoreText(overview)
                        .font(.footnote)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
            }
            .aspectRatio(cardAspectRatio, contentMode: .fit)
        }

        @ViewBuilder
        private func mediaSourceCard(for mediaSource: MediaSourceInfo, hasMultipleSources: Bool) -> some View {
            let subtitle = hasMultipleSources ? mediaSource.displayTitle : nil

            AboutCard(
                title: L10n.media,
                subtitle: subtitle
            ) {
                router.route(to: .mediaSourceInfo(source: mediaSource))
            } content: {
                if let mediaStreams = mediaSource.mediaStreams {
                    let text = mediaStreams.compactMap(\.displayTitle)
                        .joined(separator: ", ")

                    Text(text)
                        .font(.footnote)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                }
            }
            .aspectRatio(cardAspectRatio, contentMode: .fit)
        }

        @ViewBuilder
        private func ratingsCard(criticRating: Float, communityRating: Float) -> some View {
            AboutCard(
                title: L10n.ratings,
                action: {}
            ) {
                if criticRating > -1 {
                    HStack {
                        Group {
                            if criticRating >= 60 {
                                Image(.tomatoFresh)
                                    .symbolRenderingMode(.multicolor)
                                    .foregroundStyle(.green, .red)
                            } else {
                                Image(.tomatoRotten)
                                    .symbolRenderingMode(.monochrome)
                                    .foregroundColor(.green)
                            }
                        }
                        .font(.largeTitle)

                        // swiftlint:disable:next hard_coded_display_string
                        Text("\(criticRating, specifier: "%.0f")")
                            .fontWeight(.semibold)
                    }
                }

                if communityRating > -1 {
                    HStack {
                        Image(systemName: "star.fill")
                            .symbolRenderingMode(.multicolor)
                            .foregroundStyle(.yellow)
                            .font(.largeTitle)

                        // swiftlint:disable:next hard_coded_display_string
                        Text("\(communityRating, specifier: "%.1f")")
                            .fontWeight(.semibold)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }

        private var cardHeight: CGFloat {
            #if os(tvOS)
            400
            #else
            200
            #endif
        }

        private let cardAspectRatio: CGFloat = 1.77

        var body: some View {
            ContentGroupSection {
                ScrollView(.horizontal) {
                    HStack(spacing: PosterHStackMetrics.itemSpacing) {
                        descriptionCard

                        if let mediaSources = item.mediaSources {
                            ForEach(mediaSources) { source in
                                mediaSourceCard(for: source, hasMultipleSources: mediaSources.count > 1)
                            }
                        }

                        if item.criticRating != nil || item.communityRating != nil {
                            ratingsCard(
                                criticRating: item.criticRating ?? -1,
                                communityRating: item.communityRating ?? -1
                            )
                        }
                    }
                    .edgePadding(.horizontal)
                }
                .scrollIndicators(.hidden)
                .backport
                .scrollClipDisabled()
                #if os(tvOS)
                    .withViewContext(.isOverComplexContent)
                #endif
                    .frame(height: cardHeight)
                    .frame(maxWidth: .infinity)
            } header: {
                Text(L10n.about)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                    .edgePadding(.horizontal)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(L10n.about)
        }
    }
}
