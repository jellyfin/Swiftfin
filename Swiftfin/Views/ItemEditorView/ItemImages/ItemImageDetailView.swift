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

struct ItemImageDetailView: View {

    @ObservedObject
    var viewModel: ItemImageViewModel

    @Router
    private var router

    let imageInfo: ImageInfo

    private var imageSource: ImageSource? {
        guard let itemID = viewModel.item.id else { return nil }
        guard let userSession = viewModel.userSession else { return nil }
        return imageInfo.itemImageSource(
            itemID: itemID,
            client: userSession.client
        )
    }

    var body: some View {
        List {
            Section {
                if let imageSource {
                    ImageView(imageSource)
                        .placeholder { _ in
                            Image(systemName: "photo")
                        }
                        .failure {
                            Image(systemName: "questionmark")
                        }
                        .pipeline(.Swiftfin.other)
                }
            }
            .scaledToFit()
            .frame(maxHeight: 300)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .listRowCornerRadius(0)
            .listRowInsets(.zero)

            Section(L10n.details) {
                if let width = imageInfo.width, let height = imageInfo.height {
                    LabeledContent(
                        L10n.dimensions,
                        value: "\(width) x \(height)"
                    )
                }

                if let index = imageInfo.imageIndex {
                    LabeledContent(L10n.indexNumber, value: index.description)
                }
            }

            if let url = imageSource?.url {
                Section {
                    ChevronButton(
                        L10n.imageSource,
                        external: true
                    ) {
                        UIApplication.shared.open(url)
                    }
                }
            }

            StateAdapter(initialValue: false) { isPresented in
                Section {
                    Button(L10n.delete, role: .destructive) {
                        isPresented.wrappedValue = true
                    }
                    .disabled(viewModel.background.is(.deleting))
                }
                .confirmationDialog(
                    L10n.delete,
                    isPresented: isPresented,
                    titleVisibility: .visible
                ) {
                    Button(L10n.delete, role: .destructive) {
                        viewModel.deleteImage(imageInfo)
                    }
                } message: {
                    Text(L10n.deleteItemConfirmation)
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
            if viewModel.background.is(.deleting) {
                ProgressView()
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case .deleted:
                UIDevice.feedback(.success)
                router.dismiss()
            case .updated:
                break
            }
        }
        .errorMessage($viewModel.error)
    }
}
