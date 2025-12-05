//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ItemMetadataRefreshView: PlatformView {

    @Router
    private var router

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var viewModel: RefreshMetadataViewModel

    @State
    private var metadataRefreshMode: MetadataRefreshMode = .default
    @State
    private var imageRefreshMode: MetadataRefreshMode = .default

    @State
    private var replaceMetadata: Bool = false
    @State
    private var replaceImages: Bool = false
    @State
    private var regenerateTrickplay: Bool = false

    #if os(tvOS)
    @FocusState
    private var focusedItem: FocusableItem?

    private enum FocusableItem: Hashable {
        case type
    }
    #endif

    var iOSView: some View {
        Form {
            typeView
            toggleView
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarCloseButton {
            router.dismiss()
        }
        .topBarTrailing {
            runButton
                .buttonStyle(.toolbarPill)
        }
        #endif
    }

    var tvOSView: some View {
        #if os(tvOS)
        SplitFormWindowView()
            .descriptionView {
                descriptionView
            }
            .contentView {
                typeView
                toggleView

                Section {
                    runButton
                        .buttonStyle(.primary)
                        .foregroundStyle(accentColor.overlayColor, accentColor)
                }
            }
        #else
        EmptyView()
        #endif
    }

    private var runButton: some View {
        Button(L10n.run) {
            viewModel.refreshMetadata(
                metadataRefreshMode: metadataRefreshMode,
                imageRefreshMode: imageRefreshMode,
                replaceMetadata: replaceMetadata,
                replaceImages: replaceImages,
                regenerateTrickplay: regenerateTrickplay
            )
        }
    }

    private var toggleView: some View {
        Section(L10n.replace) {
            Toggle(L10n.metadata, isOn: $replaceMetadata)
            Toggle(L10n.images, isOn: $replaceImages)
            Toggle(L10n.trickplays, isOn: $regenerateTrickplay)
        }
        .navigationTitle(L10n.refreshMetadata.localizedCapitalized)
        .onReceive(viewModel.events) { event in
            switch event {
            case .refreshing:
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
    }

    private var learnMoreContent: [LabeledContent<Text, Text>] {
        [
            // TODO: Localize and also this is terrible. There's gotta be a better way to share this than this array...
            LabeledContent(
                L10n.none,
                value: "Skip the refresh for this metadata type."
            ),
            LabeledContent(
                L10n.validationOnly,
                value: "Only refresh this metadata type if there currently is no metadata."
            ),
            LabeledContent(
                L10n.default,
                value: "Refresh this metadata type using only the default metadata provider."
            ),
            LabeledContent(
                L10n.fullRefresh,
                value: "Refresh this metadata type using all available metadata providers."
            ),
        ]
    }

    #if os(iOS)
    private var typeView: some View {
        Section {
            Picker(L10n.metadata, selection: $metadataRefreshMode) {
                ForEach(MetadataRefreshMode.allCases, id: \.self) { mode in
                    Text(mode.displayTitle)
                        .tag(mode)
                }
            }

            Picker(L10n.images, selection: $imageRefreshMode) {
                ForEach(MetadataRefreshMode.allCases, id: \.self) { mode in
                    Text(mode.displayTitle)
                        .tag(mode)
                }
            }
        } header: {
            Text(L10n.refreshType)
        } footer: {
            LearnMoreButton(L10n.refreshType.localizedCapitalized) {
                learnMoreContent[0]
                learnMoreContent[1]
                learnMoreContent[2]
                learnMoreContent[3]
            }
        }
    }
    #else
    private var typeView: some View {
        Section(L10n.refreshType) {
            ListRowMenu(L10n.metadata, selection: $metadataRefreshMode)
                .focused($focusedItem, equals: .type)
            ListRowMenu(L10n.images, selection: $imageRefreshMode)
                .focused($focusedItem, equals: .type)
        }
    }
    #endif

    #if os(tvOS)
    private var descriptionView: some View {
        ZStack {
            Image(systemName: "arrow.clockwise")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400)

            focusedDescription
                .transition(.opacity.animation(.linear(duration: 0.2)))
        }
    }

    @ViewBuilder
    private var focusedDescription: some View {
        switch focusedItem {
        case .type:
            LearnMoreModal {
                learnMoreContent[0]
                learnMoreContent[1]
                learnMoreContent[2]
                learnMoreContent[3]
            }

        case nil:
            EmptyView()
        }
    }
    #endif
}
