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
        List {
            FormItemSection(item: manager.item)

            ForEach(availableProviders, id: \.route) { provider in
                section(for: provider)
            }

            if availableProviders.isEmpty {
                noTargetsSection
            }
        }
        .navigationTitle(L10n.output)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .if(UIDevice.isPhone) { view in
                view.presentationDetents([.medium, .large])
            }
        #endif
            .onFirstAppear {
                    availableProviders.forEach { $0.refresh() }
                }
                .navigationBarCloseButton {
                    router.dismiss()
                }
    }

    @ViewBuilder
    private func section(for provider: any RemotePlaybackProvider) -> some View {
        switch provider.kind {
        case .systemPicker:
            Section {
                systemPickerRow(provider)
            }
        case .deviceList:
            if provider.targets.isNotEmpty {
                Section(provider.route.displayTitle) {
                    ForEach(provider.targets) { target in
                        targetRow(provider, target)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var noTargetsSection: some View {
        Section {
            // swiftlint:disable:next hard_coded_display_string
            Text("No valid targets")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func systemPickerRow(_ provider: any RemotePlaybackProvider) -> some View {
        StateAdapter(initialValue: false) { presentAirplayRoutePicker in
            ListRow {
                Image(systemName: provider.route.systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
                    .frame(width: 60, height: 60)
                    .foregroundStyle(provider.isActive ? AnyShapeStyle(accentColor) : AnyShapeStyle(.primary))
            } content: {
                HStack {
                    // swiftlint:disable:next hard_coded_display_string
                    Text("\(L10n.airPlay) & \(L10n.bluetooth)")
                        .font(.headline)

                    Spacer()

                    ListRowCheckbox()
                }
            } action: {
                presentAirplayRoutePicker.wrappedValue = true
            }
            .isSeparatorVisible(false)
            .isSelected(provider.isActive)
            .airplayRoutePicker(present: presentAirplayRoutePicker)
        }
    }

    @ViewBuilder
    private func targetRow(_ provider: any RemotePlaybackProvider, _ target: RemotePlaybackTarget) -> some View {
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
            select(provider, target)
        }
        .isSeparatorVisible(false)
    }

    private func select(_ provider: any RemotePlaybackProvider, _ target: RemotePlaybackTarget) {
        if let session = provider.makeSession(for: target) {
            Task { await manager.remote.select(session) }
        }

        router.dismiss()
    }
}
