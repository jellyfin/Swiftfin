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
            let minWidth: CGFloat?
            let content: Content

            init(
                title: String,
                subtitle: String? = nil,
                minWidth: CGFloat? = nil,
                @ViewBuilder content: () -> Content
            ) {
                self.title = title
                self.subtitle = subtitle
                self.minWidth = minWidth
                self.content = content()
            }

            var body: some View {
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
                .frame(minWidth: minWidth, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.complexSecondary)
                )
            }
        }

        @ViewBuilder
        private var descriptionCard: some View {
            let subtitle = item.taglines?.first

            Button {
                router.route(to: .itemOverview(item: item))
            } label: {
                AboutCard(title: item.displayTitle, subtitle: subtitle) {
                    if let overview = item.overview, overview.isNotEmpty {
                        Text(overview)
                            .font(.footnote)
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .foregroundStyle(.primary, .secondary)
            .buttonStyle(.card)
        }

        @ViewBuilder
        private func mediaSourceCard(for mediaSource: MediaSourceInfo, hasMultipleSources: Bool) -> some View {
            let subtitle = hasMultipleSources ? mediaSource.displayTitle : nil

            Button {
                router.route(to: .mediaSourceInfo(source: mediaSource))
            } label: {
                AboutCard(title: L10n.media, subtitle: subtitle) {
                    if let mediaStreams = mediaSource.mediaStreams {
                        let text = mediaStreams.compactMap(\.displayTitle)
                            .joined(separator: ", ")

                        Text(text)
                            .font(.footnote)
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .foregroundStyle(.primary, .secondary)
            .buttonStyle(.card)
        }

        @ViewBuilder
        private func ratingsCard(criticRating: Float, communityRating: Float) -> some View {
            Button {} label: {
                AboutCard(title: L10n.ratings, minWidth: 200) {
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
            }
            .foregroundStyle(.primary, .secondary)
            .buttonStyle(.card)
        }

        private var cardHeight: CGFloat {
            #if os(tvOS)
            400
            #else
            200
            #endif
        }

        private let cardAspectRatio: CGFloat = 1.77

        private var cardSize: CGSize {
            .init(width: cardHeight * cardAspectRatio, height: cardHeight)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Section {
                    ScrollView(.horizontal) {
                        HStack(spacing: UIDevice.isPhone ? EdgeInsets.edgePadding / 2 : 40) {
                            descriptionCard
                                .frame(width: cardSize.width, height: cardSize.height)

                            if let mediaSources = item.mediaSources {
                                ForEach(mediaSources) { source in
                                    mediaSourceCard(for: source, hasMultipleSources: mediaSources.count > 1)
                                        .frame(width: cardSize.width, height: cardSize.height)
                                }
                            }

                            if item.criticRating != nil || item.communityRating != nil {
                                ratingsCard(
                                    criticRating: item.criticRating ?? -1,
                                    communityRating: item.communityRating ?? -1
                                )
                                .frame(width: cardSize.width, height: cardSize.height)
                            }
                        }
                        .edgePadding(.horizontal)
                    }
                    #if os(tvOS)
                    .scrollClipDisabled()
                    .withViewContext(.isOverComplexContent)
                    #endif
                    .frame(height: cardSize.height)
                    .frame(maxWidth: .infinity)
                } header: {
                    Text(L10n.about)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                        .edgePadding(.horizontal)
                }
            }
        }
    }
}
