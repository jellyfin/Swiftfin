//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct RefreshMetadataView: View {

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

    var body: some View {
        Form(systemImage: "arrow.clockwise") {

            Section {
                #if os(iOS)
                Picker(L10n.type, selection: $refreshType)
                #else
                ListRowMenu(L10n.type, selection: $refreshType)
                #endif
            } header: {
                Text(L10n.refreshMode)
            } footer: {
                Text(L10n.metadataRefreshDescription)
            }

            if refreshType != .scan {
                Section(L10n.replace) {
                    Toggle(L10n.images, isOn: $replaceImages)
                    Toggle(L10n.trickplays, isOn: $regenerateTrickplay)
                }
            }

            #if os(tvOS)
            Section {
                Button(L10n.run, action: onRun)
                    .buttonStyle(.primary)
                    .foregroundStyle(accentColor.overlayColor, accentColor)
            }
            #endif
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
                Button(L10n.run, action: onRun)
                    .buttonStyle(.toolbarPill)
            }
        #endif
    }

    private func onRun() {
        viewModel.refreshMetadata(
            metadataRefreshMode: refreshType.metadataRefreshMode,
            imageRefreshMode: refreshType.metadataRefreshMode,
            replaceMetadata: refreshType.replaceMetadata,
            replaceImages: refreshType.replaceElements(replaceImages),
            regenerateTrickplay: refreshType.replaceElements(regenerateTrickplay)
        )
    }
}
