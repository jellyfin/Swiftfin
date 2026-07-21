//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVKit
import Defaults
import Engine
import FactoryKit
import SwiftUI

struct RemotePlaybackPickerView: View {

    @Router
    private var router

    @InjectedObject(\.mediaPlayerManager)
    private var manager: MediaPlayerManager

    var body: some View {
        Form {
            FormItemSection(item: manager.item)

            if manager.remote.availableProviders.isEmpty {
                Section {
                    Text(L10n.noValidTarget)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                ForEach(manager.remote.availableProviders, id: \.route) { provider in
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
        .navigationTitle(L10n.outputs)
        .onFirstAppear {
            manager.remote.refresh()
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
                    .overlay {
                        AirplayRoutePickerView(present: presentAirplayRoutePicker)
                            .allowsHitTesting(false)
                    }
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
                            if provider.isActive(target) {
                                manager.remote.end()
                            } else if let session = provider.makeSession(for: target) {
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

private struct AirplayRoutePickerView: UIViewRepresentable {

    @Binding
    var present: Bool

    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView()

        routePickerView.prioritizesVideoDevices = true
        routePickerView.tintColor = .clear
        routePickerView.activeTintColor = .clear
        routePickerView.alpha = 0

        return routePickerView
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        guard present else { return }

        DispatchQueue.main.async {
            present = false

            for subview in uiView.subviews {
                if let button = subview as? UIButton {
                    button.sendActions(for: .touchUpInside)
                }
            }
        }
    }
}
