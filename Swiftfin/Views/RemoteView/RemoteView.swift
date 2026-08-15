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

struct RemoteView: View {

    @StateObject
    private var viewModel = CastViewModel()

    @State
    private var isCastPending = false
    @State
    private var proxy: CastMediaPlayerProxy?

    let provider: MediaPlayerItemProvider?

    private var selectedTarget: SessionViewModel? {
        viewModel.selectedTarget
    }

    private func cast(to target: SessionViewModel, replaceConfirmation: Binding<Bool>) {
        guard let provider else { return }

        if CastMediaPlayerProxy.isPlaying(item: provider.item, in: target.session) {
            proxy = CastMediaPlayerProxy(item: provider.item, session: target)
        } else if let nowPlayingItem = target.session.nowPlayingItem {
            proxy = CastMediaPlayerProxy(item: nowPlayingItem, session: target)
            replaceConfirmation.wrappedValue = true
        } else {
            castReplacing(provider: provider, target: target)
        }
    }

    private func castReplacing(provider: MediaPlayerItemProvider, target: SessionViewModel) {
        guard let itemID = provider.item.id else { return }

        target.error = nil

        Task {
            await target.remotePlaybackSession(
                command: .playNow,
                itemIDs: [itemID],
                startPositionTicks: provider.item.userData?.playbackPositionTicks,
                mediaSourceID: provider.mediaSource?.id,
                audioStreamIndex: nil,
                subtitleStreamIndex: nil,
                startIndex: nil
            )

            await target.refresh()
        }

        proxy = CastMediaPlayerProxy(item: provider.item, session: target)
    }

    @ViewBuilder
    private var targetPicker: some View {
        Menu(
            selectedTarget?.session.deviceName ?? L10n.selectDevice.localizedCapitalized,
            systemImage: "chevron.down"
        ) {
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
                        Text(session.session.deviceName ?? L10n.unknown)
                            .tag(session.id)
                    }
                }
            }
        }
        .labelStyle(
            CapsuleLabelStyle(
                insets: .init(vertical: 11, horizontal: 16),
                isIconTrailing: true
            )
        )
        .font(.headline)
        .menuStyle(.button)
        .buttonStyle(.isPressed { isPressed in
            viewModel.isPaused = isPressed
            proxy?.isSyncSuspended = isPressed
        })
    }

    @ViewBuilder
    private var castButton: some View {
        if let provider, let selectedTarget,
           !CastMediaPlayerProxy.isPlaying(item: provider.item, in: selectedTarget.session)
        {
            StateAdapter(initialValue: false) { isPresentingReplaceConfirmation in
                castButtonContent(
                    provider: provider,
                    target: selectedTarget,
                    replaceConfirmation: isPresentingReplaceConfirmation
                )
            }
        }
    }

    @ViewBuilder
    private func castButtonContent(
        provider: MediaPlayerItemProvider,
        target: SessionViewModel,
        replaceConfirmation: Binding<Bool>
    ) -> some View {
        Button {
            isCastPending = true
            cast(to: target, replaceConfirmation: replaceConfirmation)
        } label: {
            Group {
                if isCastPending {
                    ProgressView()
                } else {
                    Label(
                        L10n.castToDevice,
                        systemImage: "tv.badge.wifi"
                    )
                    .font(.subheadline)
                    .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .backport
            .glassEffect(
                .regular.selection(
                    tint: .blue,
                    foregroundColor: Color.blue.overlayColor
                ),
                in: .capsule
            )
        }
        .buttonStyle(BasicHoverButtonStyle())
        .disabled(isCastPending)
        .edgePadding(.horizontal)
        .alert(
            L10n.replace,
            isPresented: replaceConfirmation
        ) {
            Button(L10n.replace, role: .destructive) {
                castReplacing(provider: provider, target: target)
            }

            Button(L10n.cancel, role: .cancel) {
                isCastPending = false
            }
        } message: {
            Text(
                L10n.replaceQueueWarning(
                    target.session.nowPlayingItem?.displayTitle ?? L10n.unknown,
                    provider.item.displayTitle
                )
            )
        }
    }

    @ViewBuilder
    private var disabledRemote: some View {
        VStack(spacing: 20) {
            if viewModel.state == .initial {
                ProgressView()
            } else if viewModel.targets.isEmpty {
                Text(L10n.noDevicesFound)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

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
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                if let proxy, let selectedTarget {
                    ControlsView(
                        proxy: proxy,
                        viewModel: viewModel
                    )
                    .id(selectedTarget.id)
                    .transition(.opacity)
                } else {
                    disabledRemote
                        .transition(.opacity)
                }
            }

            castButton
        }
        .edgePadding([.top, .bottom])
        .presentationDragIndicator(.visible)
        .animation(.linear(duration: 0.2), value: selectedTarget?.id)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                targetPicker
            }
        }
        .errorMessage($viewModel.error)
        .onFirstAppear {
            viewModel.refresh()
        }
        .onChange(of: selectedTarget?.id) { _, newValue in
            isCastPending = false

            guard newValue != proxy?.session.id else { return }
            proxy = selectedTarget.map { CastMediaPlayerProxy(item: nil, session: $0) }
        }
        .onChange(of: selectedTarget?.session.nowPlayingItem?.id) { _, _ in
            isCastPending = false
        }
        .onChange(of: selectedTarget?.error == nil) { _, hasNoError in
            guard !hasNoError else { return }
            isCastPending = false
        }
    }
}
