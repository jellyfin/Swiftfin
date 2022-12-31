//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension HomeView {
    struct HomeItemRow: View {
        @EnvironmentObject
        private var router: HomeCoordinator.Router
        @Environment(\.safeAreaInsets)
        private var edgeInsets: EdgeInsets

        public let items: [BaseItemDto]
        public let size: Columns
        public let focusPrefix: String
        public let focusedImage: FocusState<String?>.Binding

        var body: some View {
            ZStack(alignment: .top) {
                ScrollView(.horizontal) {
                    let isHero = focusPrefix == "hero"

                    LazyHStack(alignment: isHero ? .bottom : .center, spacing: 40) {
                        ForEach(items, id: \.id) { item in
                            let focusName = "\(focusPrefix)::\(item.id!)"
                            let isFocused = focusedImage.wrappedValue == focusName

                            VStack {
                                Button {
                                    router.route(to: \.item, item)
                                } label: {
                                    ImageView(item.landscapePosterImageSources(maxWidth: size.rawValue))
                                        .aspectRatio(16 / 9, contentMode: .fit)
                                        .cornerRadius(7.5)
                                        .frame(width: size.rawValue, height: size.rawValue / (16 / 9))
                                        .overlay {
                                            if let progress = item.userData?.playedPercentage, progress != 0 {
                                                ZStack(alignment: .bottom) {
                                                    LinearGradient
                                                        .linearGradient(
                                                            Gradient(colors: [.black.opacity(0.75), .black.opacity(0)]),
                                                            startPoint: .bottom,
                                                            endPoint: .center
                                                        )
                                                        .animation(.easeInOut(duration: 0.25), value: isFocused)
                                                        .opacity(isFocused ? 1 : 0)

                                                    VStack(alignment: .leading) {
                                                        Spacer()

                                                        Text(L10n.remaining(item.progress ?? "?"))
                                                            .bold()
                                                            .font(.caption2)
                                                            .textCase(.uppercase)
                                                            .padding(.bottom, -15)
                                                            .animation(.easeInOut(duration: 0.25), value: isFocused)
                                                            .opacity(isFocused ? 1 : 0)

                                                        ProgressBar(progress: progress / 100)
                                                            .frame(height: 5)
                                                    }
                                                    .padding(10)
                                                }
                                            }
                                        }
                                }
                                // This should apply
                                .buttonStyle(CardButtonStyle())
                                .focused(focusedImage, equals: focusName)
                                .animation(.easeInOut(duration: 0.25), value: focusedImage.wrappedValue)
                                .padding(.bottom, isFocused && isHero ? 11 : 0)

                                HStack(spacing: 0) {
                                    Text(item.displayName)
                                        .foregroundColor(isFocused ? Color.primary : Color.gray)

                                    if item.parentIndexNumber != nil || item.indexNumber != nil {
                                        Text("•")
                                            .padding(.horizontal, 4)
                                    }
                                    if let parentIndexNumber = item.parentIndexNumber {
                                        Text("S\(parentIndexNumber)")
                                    }
                                    if let indexNumber = item.indexNumber {
                                        Text("E\(indexNumber)")
                                    }
                                }
                                .font(.caption)
                                .offset(y: !isHero && isFocused ? 10 : 0)
                                .animation(.easeInOut(duration: 0.25), value: focusedImage.wrappedValue)
                                .foregroundColor(Color.gray)
                                .lineLimit(1)
                            }
                            .frame(width: size.rawValue)
                        }
                    }
                    .frame(height: (size.rawValue / (16 / 9)) * 1.22 + 22)
                    .padding(.leading, edgeInsets.leading)
                    .padding(.trailing, edgeInsets.trailing)
                }
            }
        }

        public enum Columns: CGFloat {
            case four = 410
            case five = 320
        }
    }
}
