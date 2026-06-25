//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Engine
import Factory
import SwiftUI

struct RemotePlaybackPickerView: View {

    @Default(.accentColor)
    private var accentColor

    @Router
    private var router

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    private var availableProviders: [any RemotePlaybackProvider] {
        manager.remote.availableProviders
    }

    var body: some View {
        Form {
            FormItemSection(item: manager.item)

            if availableProviders.isEmpty {
                Section {
                    // swiftlint:disable:next hard_coded_display_string
                    Text("No valid targets")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                ForEach(availableProviders, id: \.route) { provider in
                    providerSection(for: provider)
                }
            }
        } image: {
            PosterImage(
                item: manager.item,
                type: manager.item.preferredPosterDisplayType
            )
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400)
        }
        .navigationTitle(L10n.output)
        .onFirstAppear {
            availableProviders.forEach { $0.refresh() }
        }
        .navigationBarCloseButton {
            router.dismiss()
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .if(UIDevice.isPhone) { view in
            view.presentationDetents([.medium, .large])
        }
        #endif
    }

    @ViewBuilder
    private func providerSection(for provider: any RemotePlaybackProvider) -> some View {
        switch provider.kind {
        case .systemPicker:
            Section {
                StateAdapter(initialValue: false) { presentAirplayRoutePicker in
                    ChevronButton("\(L10n.airPlay) & \(L10n.bluetooth)", systemName: provider.route.systemImage) {
                        presentAirplayRoutePicker.wrappedValue = true
                    }
                    .isEditing(provider.isActive)
                    .isSelected(provider.isActive)
                    .airplayRoutePicker(present: presentAirplayRoutePicker)
                }
            }
        case .deviceList:
            if provider.targets.isNotEmpty {
                Section(provider.route.displayTitle) {
                    ForEach(provider.targets) { target in
                        ListRow {
                            Image(systemName: target.systemImage ?? provider.route.systemImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(8)
                                .frame(width: 60, height: 60)
                        } content: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(target.title)
                                        .font(.headline)

                                    if let subtitle = target.subtitle {
                                        Text(subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                ListRowCheckbox()
                            }
                            .isEditing(true)
                            .isSelected(provider.isActive(target))
                        } action: {
                            if let session = provider.makeSession(for: target) {
                                Task {
                                    await manager.remote.select(session)
                                }
                            }

                            router.dismiss()
                        }
                    }
                }
            }
        }
    }
}
