//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

// TODO: break out

struct AnyMediaPlayerSupplement: Equatable, Identifiable {

    let supplement: any MediaPlayerSupplement

    init(supplement: any MediaPlayerSupplement) {
        self.supplement = supplement
    }

    var id: String {
        supplement.id
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.supplement.id == rhs.supplement.id
    }
}

protocol MediaPlayerSupplement: Equatable, Identifiable<String> {

    associatedtype Body: View

    var title: String { get }

    func makeBody() -> Self.Body
}

extension MediaPlayerSupplement where Body == EmptyView {

    func makeBody() -> EmptyView {
        EmptyView()
    }
}

extension MediaPlayerSupplement where ID == String {

    var id: String { title }
}

struct ChapterDrawerButton {

//    weak var manager: MediaPlayerManager?
    let title: String = "Chapters"

    func makeBody() -> some View {
        Color.red
    }
}

struct ItemInfoDrawerProvider: MediaPlayerSupplement {

//    weak var manager: MediaPlayerManager?
    let title: String = "Info"
    let item: BaseItemDto

    func makeBody() -> some View {
        _View(item: item)
    }

    struct _View: View {

        @Environment(\.safeAreaInsets)
        @Binding
        private var safeAreaInsets
        
        @State
        private var contentSize: CGSize = .zero

        let item: BaseItemDto

        @ViewBuilder
        private var accessoryView: some View {
            DotHStack {
                if item.type == .episode, let seasonEpisodeLocator = item.seasonEpisodeLabel {
                    Text(seasonEpisodeLocator)
                } else if let premiereYear = item.premiereDateYear {
                    Text(premiereYear)
                }

                if let runtime = item.runTimeLabel {
                    Text(runtime)
                }

                if let officialRating = item.officialRating {
                    Text(officialRating)
                }
            }
        }

        var body: some View {
            HStack(alignment: .bottom, spacing: EdgeInsets.edgePadding) {
                ZStack {
                    Color.clear

                    ImageView(item.portraitImageSources(maxWidth: 60))
                        .failure {
                            SystemImageContentView(systemName: item.systemImage)
                        }
                }
                .posterStyle(.portrait, contentMode: .fit)
                .posterShadow()

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.displayTitle)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let overview = item.overview {
                        Text(overview)
                            .font(.subheadline.weight(.semibold))
                    }

                    accessoryView
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
//                .frame(maxHeight: .infinity, alignment: .center)
                
                VStack {
                    Button {} label: {
                        ZStack {
//                            RoundedRectangle(cornerRadius: 7)
//                                .fill(Color.gray.opacity(0.1))
                            BlurView()
                                .cornerRadius(7)

                            Label("From Beginning", systemImage: "play.fill")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(width: 150, height: 50)
                    }
                }
            }
            .padding(.horizontal, safeAreaInsets.leading)
            .trackingSize($contentSize)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ItemInfoDrawerProvider(item: .init(
            indexNumber: 1,
            name: "The Bear",
            parentIndexNumber: 1,
            runTimeTicks: 10_000_000_000,
            type: .episode
        ))
        .makeBody()
        .eraseToAnyView()
        .environment(\.safeAreaInsets, .constant(EdgeInsets.edgeInsets))
        .frame(height: 110)
        .previewInterfaceOrientation(.landscapeRight)
    }
}
