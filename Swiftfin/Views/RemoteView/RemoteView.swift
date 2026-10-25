//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct RemoteView: View {

    @StateObject
    private var viewModel = CastViewModel()

    @State
    private var proxy: CastMediaPlayerProxy?

    @Router
    private var router

    private var selectedTarget: SessionViewModel? {
        viewModel.selectedTarget
    }

    private var selectorTitle: String {
        if viewModel.state == .content && viewModel.targets.isEmpty {
            L10n.noDevicesFound
        } else {
            selectedTarget?.session.deviceName ?? L10n.selectDevice.localizedCapitalized
        }
    }

    var body: some View {
        ZStack {
            if let proxy, let selectedTarget {
                ControlsView(
                    proxy: proxy,
                    viewModel: viewModel
                )
                .id(selectedTarget.id)
                .transition(.opacity)
            } else {
                VStack(spacing: 20) {
                    Touchpad { _ in }

                    HStack(spacing: 24) {
                        Button(L10n.back, systemImage: "chevron.backward") {}
                            .buttonStyle(.remoteControl)

                        Button(L10n.play, systemImage: "play.fill") {}
                            .buttonStyle(.remoteControl(size: .large))

                        Button(L10n.home, systemImage: "house.fill") {}
                            .buttonStyle(.remoteControl)
                    }
                }
                .foregroundStyle(.secondary)
                .edgePadding(.horizontal)
                .disabled(true)
                .transition(.opacity)
            }
        }
        .edgePadding([.top, .bottom])
        .animation(.linear(duration: 0.2), value: selectedTarget?.id)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Menu {
                    Picker(
                        L10n.selectDevice.localizedCapitalized,
                        selection: Binding(
                            get: { selectedTarget?.id },
                            set: { newID in
                                viewModel.select(viewModel.targets.values.first { $0.id == newID })
                            }
                        )
                    ) {
                        Section {
                            Text(L10n.none)
                                .tag(nil as String?)
                        }

                        Section {
                            ForEach(viewModel.targets.values.elements, id: \.id) { session in
                                VStack(alignment: .leading) {
                                    Text(session.session.deviceName ?? L10n.unknown)

                                    if let client = session.session.client {
                                        Text(client)
                                    }
                                }
                                .tag(session.id)
                            }
                        }
                    }
                } label: {
                    Group {
                        if viewModel.state == .content && viewModel.targets.isEmpty {
                            EmptyLabel(selectorTitle)
                        } else {
                            Label(selectorTitle, systemImage: "chevron.down")
                        }
                    }
                    .labelStyle(.trailingIcon)
                    .padding(.init(vertical: 11, horizontal: 16))
                    .backport
                    .glassEffect(in: .capsule)
                }
                .font(.headline)
                .menuStyle(.button)
                .buttonStyle(.isPressed { isPressed in
                    viewModel.isPaused = isPressed
                    proxy?.isSyncSuspended = isPressed
                })
                .disabled(viewModel.targets.isEmpty)
                .id(selectorTitle)
            }
        }
        .navigationBarCloseButton {
            router.dismiss()
        }
        .errorMessage($viewModel.error)
        .onFirstAppear {
            viewModel.refresh()
        }
        .onChange(of: selectedTarget?.id) { _, newValue in
            guard newValue != proxy?.session.id else { return }

            proxy = selectedTarget.map { CastMediaPlayerProxy(item: nil, session: $0) }
        }
    }
}
