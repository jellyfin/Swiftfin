//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import JellyfinAPI
import SwiftUI

struct RemoteImageDetailView: View {

    @Router
    private var router

    @ObservedObject
    private var viewModel: ItemImageViewModel

    private let remoteImageInfo: RemoteImageInfo
    private let imageSource: ImageSource

    init(
        viewModel: ItemImageViewModel,
        remoteImageInfo: RemoteImageInfo
    ) {
        self.viewModel = viewModel
        self.remoteImageInfo = remoteImageInfo
        self.imageSource = remoteImageInfo.imageSource()
    }

    var body: some View {
        List {
            Section {
                ImageView(imageSource)
                    .placeholder { _ in
                        Image(systemName: "photo")
                    }
                    .failure {
                        Image(systemName: "photo")
                    }
                    .pipeline(.Swiftfin.other)
            }
            .scaledToFit()
            .frame(maxHeight: 300)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowCornerRadius(0)
            .listRowInsets(.zero)

            Section(L10n.details) {
                if let provider = remoteImageInfo.providerName {
                    LabeledContent(L10n.provider, value: provider)
                }

                if let language = remoteImageInfo.language {
                    LabeledContent(L10n.language, value: language)
                }

                if let width = remoteImageInfo.width, let height = remoteImageInfo.height {
                    LabeledContent(
                        L10n.dimensions,
                        value: "\(width) x \(height)"
                    )
                }
            }

            if let rating = remoteImageInfo.communityRating {
                Section(L10n.ratings) {
                    LabeledContent(L10n.rating, value: rating.formatted(.number.precision(.fractionLength(2))))

                    if let ratingVotes = remoteImageInfo.voteCount {
                        LabeledContent(L10n.votes, value: ratingVotes, format: .number)
                    }
                }
            }

            if let url = imageSource.url {
                Section {
                    ChevronButton(
                        L10n.imageSource,
                        external: true
                    ) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .backport
        .toolbarTitleDisplayMode(.inline)
        .navigationTitle(L10n.image)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            if viewModel.background.is(.updating) {
                ProgressView()
            }

            Button(L10n.save) {
                viewModel.save()
            }
            .buttonStyle(.toolbarPill)
            .disabled(viewModel.background.is(.updating))
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .updated:
                UIDevice.feedback(.success)
                router.dismiss()
            case .deleted:
                break
            }
        }
        .errorMessage($viewModel.error)
    }
}
