//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemEditorView {

    struct RefreshMetadataButton: View {

        @StateObject
        private var viewModel: RefreshMetadataViewModel

        @State
        private var isPresentingEventAlert = false
        @State
        private var error: JellyfinAPIError?
        @State
        private var isFinishing = false
        @State
        private var isLoading = false

        // MARK: - Initializer

        init(item: BaseItemDto) {
            _viewModel = StateObject(wrappedValue: RefreshMetadataViewModel(item: item))
        }

        // MARK: - Body

        var body: some View {
            Menu {
                Button {
                    viewModel.send(
                        .refreshMetadata(
                            metadataRefreshMode: .default,
                            imageRefreshMode: .default,
                            replaceMetadata: true,
                            replaceImages: false
                        )
                    )
                } label: {
                    Label(
                        L10n.refresh,
                        systemImage: "arrow.clockwise.circle"
                    )
                }

                Button {
                    viewModel.send(
                        .refreshMetadata(
                            metadataRefreshMode: .fullRefresh,
                            imageRefreshMode: .fullRefresh,
                            replaceMetadata: false,
                            replaceImages: false
                        )
                    )
                } label: {
                    Label(
                        L10n.findMissing,
                        systemImage: "magnifyingglass.circle"
                    )
                }

                Button {
                    viewModel.send(
                        .refreshMetadata(
                            metadataRefreshMode: .fullRefresh,
                            imageRefreshMode: .none,
                            replaceMetadata: true,
                            replaceImages: false
                        )
                    )
                } label: {
                    Label(
                        L10n.replaceMetadata,
                        systemImage: "document.circle"
                    )
                }

                Button {
                    viewModel.send(
                        .refreshMetadata(
                            metadataRefreshMode: .none,
                            imageRefreshMode: .fullRefresh,
                            replaceMetadata: false,
                            replaceImages: true
                        )
                    )
                } label: {
                    Label(
                        L10n.replaceImages,
                        systemImage: "photo.circle"
                    )
                }

                Button {
                    viewModel.send(
                        .refreshMetadata(
                            metadataRefreshMode: .fullRefresh,
                            imageRefreshMode: .fullRefresh,
                            replaceMetadata: true,
                            replaceImages: true
                        )
                    )
                } label: {
                    Label(
                        L10n.replaceAll,
                        systemImage: "staroflife.circle"
                    )
                }
            } label: {
                HStack {
                    Text(L10n.refreshMetadata)
                        .foregroundStyle(.primary)
                    Spacer()
                    if isLoading {
                        ProgressView(value: 0.5)
                            .progressViewStyle(.gauge)
                            .transition(.opacity.combined(with: .scale).animation(.bouncy))
                            .frame(width: 25, height: 25)
                    } else {
                        Image(systemName: isFinishing ? "checkmark" : "arrow.clockwise")
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary, .secondary)
            }
            .disabled(isLoading || isPresentingEventAlert)
            .onReceive(viewModel.events) { event in
                switch event {
                case let .error(eventError):
                    error = eventError
                    isPresentingEventAlert = true
                case let .refreshTriggered(triggerDate):

                    // TODO: Do what can I do with this date? Something track progress?
                    self.isLoading = true
                case .refreshCompleted:
                    showFeedback()
                }
            }
            .alert(
                L10n.error,
                isPresented: $isPresentingEventAlert,
                presenting: error
            ) { _ in

            } message: { error in
                Text(error.localizedDescription)
            }
        }

        // MARK: - SuccessFeedback

        private func showFeedback() {
            withAnimation {
                isLoading = false
                isFinishing = true
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isFinishing = false
                }
            }
        }
    }
}
