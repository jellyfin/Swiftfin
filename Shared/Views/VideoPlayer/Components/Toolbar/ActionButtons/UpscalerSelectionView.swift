//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct UpscalerSelectionView: View {

        @Environment(VideoPlayer.ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        private var controlFont: Font {
            #if os(tvOS)
            .footnote
            #else
            .subheadline
            #endif
        }

        private var active: MPVMediaPlayer.Upscaler {
            (mediaSession.player as? MPVMediaPlayer)?.upscaler ?? .off
        }

        private var profileTip: String? {
            switch active {
            case .off: nil
            case let .anime4K(profile): profile.description
            case let .artCNN(profile): profile.description
            }
        }

        @ContentBuilder
        private func option(_ title: String, selection: MPVMediaPlayer.Upscaler) -> some View {
            let isSelected = active == selection

            Button {
                mediaSession.setUpscaler(selection)
            } label: {
                HStack(spacing: 6) {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                    }

                    Text(title)
                }
                .font(controlFont.weight(isSelected ? .semibold : .regular))
                .fixedSize()
                .padding(.horizontal, 12)
                .frame(minHeight: 34)
                .if(isSelected) { label in
                    label.backport.glassEffect(
                        .regular.selection(tint: .white.opacity(0.25), foregroundColor: .white),
                        in: .capsule
                    )
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .disabled(!mediaSession.canControlPlayback)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .id(selection)
        }

        @ContentBuilder
        private func options(@ContentBuilder content: () -> some View) -> some View {
            let row = HStack(spacing: 4, content: content)

            ScrollViewReader { scroll in
                ScrollView(.horizontal) {
                    row
                }
                .onAppear {
                    scroll.scrollTo(active)
                }
                .onChange(of: active) {
                    scroll.scrollTo(active)
                }
            }
        }

        @ContentBuilder
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    options {
                        option(L10n.off, selection: .off)
                        option(L10n.anime4K, selection: anime4KSelection)
                        option(L10n.artCNNC4F16, selection: artCNNSelection)
                    }
                    .accessibilityLabel(L10n.upscalers)
                    Button(action: { viewState.isPresentingUpscalers = false }) {
                        Label(L10n.close, systemImage: "xmark")
                            .labelStyle(.iconOnly)
                            .font(controlFont.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }

                if let profileTip {
                    Divider()

                    options {
                        switch active {
                        case .off:
                            EmptyView()

                        case .anime4K:
                            ForEach(Anime4KProfile.allCases, id: \.self) { profile in
                                option(profile.displayTitle, selection: .anime4K(profile))
                            }

                        case .artCNN:
                            ForEach(ArtCNNProfile.allCases, id: \.self) { profile in
                                option(profile.displayTitle, selection: .artCNN(profile))
                            }
                        }
                    }
                    .accessibilityLabel(L10n.profile)

                    Text(profileTip)
                        .font(controlFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .accessibilityLabel(profileTip)
                }
            }
            .padding(16)
            .foregroundStyle(.primary)
            .tint(.primary)
            #if os(iOS)
            .buttonStyle(.plain)
            #else
            .buttonStyle(RemoteButtonStyle())
            .focusEffectDisabled()
            #endif
        }

        #if os(tvOS)
        private struct RemoteButtonStyle: ButtonStyle {

            @Environment(\.isFocused)
            private var isFocused

            @ContentBuilder
            func makeBody(configuration: Configuration) -> some View {
                configuration.label
                    .overlay {
                        if isFocused {
                            Capsule()
                                .strokeBorder(.white, lineWidth: 2)
                                .allowsHitTesting(false)
                        }
                    }
                    .opacity(configuration.isPressed ? 0.7 : 1)
            }
        }
        #endif

        private var anime4KSelection: MPVMediaPlayer.Upscaler {
            if case .anime4K = active {
                active
            } else {
                .preferredAnime4K
            }
        }

        private var artCNNSelection: MPVMediaPlayer.Upscaler {
            if case .artCNN = active {
                active
            } else {
                .preferredArtCNN
            }
        }
    }
}

extension VideoPlayer.PlaybackControls {

    struct UpscalerOverlay: View {

        @AdaptiveLayout
        private var viewLayout
        @Environment(VideoPlayer.ViewState.self)
        private var viewState

        @ContentBuilder
        var body: some View {
            if viewState.isPresentingUpscalers {
                panel
                    .frame(maxWidth: viewLayout.isLarge ? 920 : 540)
                    .padding(.horizontal, viewLayout.edgePadding)
                    .padding(.bottom, 16)
                    .focusSection()
            }
        }

        @ContentBuilder
        private var panel: some View {
            let shape = RoundedRectangle(cornerRadius: 24)
            let selection = Toolbar.ActionButtons.UpscalerSelectionView()
                .environment(\.colorScheme, .dark)

            if #available(iOS 26.0, tvOS 26.0, *), UIDevice.supportsLiquidGlass {
                selection.glassEffect(.regular.tint(.black.opacity(0.15)), in: shape)
            } else {
                selection.background(.regularMaterial, in: shape)
            }
        }
    }
}
