//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ItemMetadataRefreshView: PlatformView {

    @Router
    private var router

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var viewModel: RefreshMetadataViewModel

    @State
    private var refreshType: MetadataRefreshType = .scan
    @State
    private var replaceImages: Bool = false
    @State
    private var regenerateTrickplay: Bool = false

    var iOSView: some View {
        Form {
            modeSection
            toggleSection
        }
        .navigationTitle(L10n.refreshMetadata.localizedCapitalized)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(viewModel.events) { event in
            if event == .refreshing {
                router.dismiss()
            }
        }
        .errorMessage($viewModel.error)
        #if os(iOS)
            .navigationBarCloseButton {
                router.dismiss()
            }
            .topBarTrailing {
                runButton
                    .buttonStyle(.toolbarPill)
            }
        #endif
    }

    // MARK: - tvOS View

    var tvOSView: some View {
        #if os(tvOS)
        SplitFormWindowView()
            .descriptionView {
                Image(systemName: "arrow.clockwise")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400)
            }
            .contentView {
                modeSection
                toggleSection

                Section {
                    runButton
                        .buttonStyle(.primary)
                        .foregroundStyle(accentColor.overlayColor, accentColor)
                }
            }
            .navigationTitle(L10n.refreshMetadata.localizedCapitalized)
            .onReceive(viewModel.events) { event in
                if event == .refreshing {
                    router.dismiss()
                }
            }
            .errorMessage($viewModel.error)
        #else
        EmptyView()
        #endif
    }

    // MARK: - Mode Section

    @ViewBuilder
    private var modeSection: some View {
        Section {
            #if os(iOS)
            CaseIterablePicker(L10n.type, selection: $refreshType)
            #else
            ListRowMenu(L10n.type, selection: $refreshType)
            #endif
        } header: {
            Text(L10n.refreshMode)
        } footer: {
            Text(L10n.metadataRefreshDescription)
        }
    }

    // MARK: - Toggle Section

    @ViewBuilder
    private var toggleSection: some View {
        if refreshType != .scan {
            Section(L10n.replace) {
                Toggle(L10n.images, isOn: $replaceImages)
                Toggle(L10n.trickplays, isOn: $regenerateTrickplay)
            }
        }
    }

    // MARK: - Run Button

    private var runButton: some View {
        Button(L10n.run) {
            viewModel.refreshMetadata(
                metadataRefreshMode: refreshType.metadataRefreshMode,
                imageRefreshMode: refreshType.metadataRefreshMode,
                replaceMetadata: refreshType.replaceMetadata,
                replaceImages: refreshType.replaceElements(replaceImages),
                regenerateTrickplay: refreshType.replaceElements(regenerateTrickplay)
            )
        }
    }
}
