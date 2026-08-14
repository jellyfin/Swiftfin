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
    private var isCastPending = false
    @State
    private var isPresentingReplaceConfirmation = false
    @State
    private var proxy: CastMediaPlayerProxy?

    let provider: MediaPlayerItemProvider?

    private var selectedTarget: SessionViewModel? {
        viewModel.selectedTarget
    }

    private func cast(to target: SessionViewModel) {
        guard let provider else { return }

        if CastMediaPlayerProxy.isPlaying(item: provider.item, in: target.session) {
            proxy = CastMediaPlayerProxy(item: provider.item, session: target)
        } else if let nowPlayingItem = target.session.nowPlayingItem {
            proxy = CastMediaPlayerProxy(item: nowPlayingItem, session: target)
            isPresentingReplaceConfirmation = true
        } else {
            castReplacing()
        }
    }

    private func castReplacing() {
        guard let provider, let target = selectedTarget, let itemID = provider.item.id else { return }

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
        Menu {
            Button {
                viewModel.select(nil)
            } label: {
                if selectedTarget == nil {
                    Label(L10n.none, systemImage: "checkmark")
                } else {
                    Text(L10n.none)
                }
            }

            Divider()

            ForEach(viewModel.targets.values.elements, id: \.id) { session in
                Button {
                    viewModel.select(session)
                } label: {
                    if session.id == selectedTarget?.id {
                        Label(session.session.deviceName ?? L10n.unknown, systemImage: "checkmark")
                    } else {
                        Text(session.session.deviceName ?? L10n.unknown)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedTarget?.session.deviceName ?? L10n.selectDevice)
                    .font(.headline)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .backport
            .glassEffect(
                .regular.selection(
                    tint: .secondarySystemBackground,
                    foregroundColor: .primary
                ),
                in: .capsule
            )
        }
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
            Button {
                isCastPending = true
                cast(to: selectedTarget)
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

            RemoteTouchpad { _ in }

            HStack(spacing: 24) {
                RemoteButton(systemImage: "chevron.backward") {}

                RemoteButton(systemImage: "play.fill", size: 76) {}

                RemoteButton(systemImage: "house.fill") {}
            }
        }
        .foregroundStyle(.secondary)
        .edgePadding([.horizontal, .bottom])
        .disabled(true)
    }

    var body: some View {
        VStack(spacing: 20) {
            if let proxy, let selectedTarget {
                RemoteControlsView(
                    proxy: proxy,
                    target: selectedTarget,
                    viewModel: viewModel
                )
            } else {
                disabledRemote
            }

            castButton
        }
        .edgePadding(.top)
        .animation(.linear(duration: 0.2), value: selectedTarget?.id)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                targetPicker
            }
        }
        .errorMessage($viewModel.error)
        .alert(
            L10n.replace,
            isPresented: $isPresentingReplaceConfirmation
        ) {
            Button(L10n.replace, role: .destructive) {
                castReplacing()
            }

            Button(L10n.cancel, role: .cancel) {
                isCastPending = false
            }
        } message: {
            Text(
                L10n.replaceQueueWarning(
                    selectedTarget?.session.nowPlayingItem?.displayTitle ?? L10n.unknown,
                    provider?.item.displayTitle ?? L10n.unknown
                )
            )
        }
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
