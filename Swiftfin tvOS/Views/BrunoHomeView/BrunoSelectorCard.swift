//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// Prototype copy is English-only; localization (L10n) is a deferred TODO (see BRUNO_NOTES.md).
// swiftlint:disable hard_coded_display_string

// MARK: - BrunoSelectorCard

//
// A branded pill selector matching the hero's chip vocabulary (BrunoHeroView.heroPill): a Capsule
// with a translucent fg wash idle, accent fill when active, and an accent focus ring + lift on
// focus — NOT a chunky media card. Used for the Genres core panel (.bucket) and the Kids filter
// (.toggle); these are controls, not content, so they read as first-class branded pills.
struct BrunoSelectorCard: View {

    enum Style {
        case toggle // dense segmented toggle (Kids All / Movies / TV Shows)
        case bucket // roomier category bucket (Genres core panel)

        var font: Font {
            switch self {
            case .toggle: .brunoBody(26, weight: .semibold)
            case .bucket: .brunoBody(30, weight: .semibold)
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .toggle: 38
            case .bucket: 46
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .toggle: 16
            case .bucket: 20
            }
        }
    }

    let title: String
    var isSelected: Bool = false
    var style: Style = .bucket
    /// Activate on FOCUS instead of on Select press — the remote cursor selects just by landing on
    /// the chip (move-to-select). Used by the Kids filter row.
    var selectsOnFocus: Bool = false
    let action: () -> Void

    @FocusState
    private var isFocused: Bool

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(style.font)
                .foregroundStyle(isSelected ? Color.bruno.page : Color.bruno.fg)
                .lineLimit(1)
                .padding(.horizontal, style.horizontalPadding)
                .padding(.vertical, style.verticalPadding)
                .background {
                    Capsule(style: .continuous)
                        .fill(
                            isSelected
                                ? Color.bruno.accent
                                : Color.bruno.fg.opacity(isFocused ? 0.22 : 0.12)
                        )
                }
                .overlay {
                    // Focus cursor: a 3px accent ring (README focus system), shown when focused but
                    // not already accent-filled. ALWAYS present and toggled via opacity — never an
                    // `if`-inserted view — so it cross-fades with the scale/fill under the value
                    // animation instead of popping in abruptly mid-scale (the janky highlight).
                    Capsule(style: .continuous)
                        .stroke(Color.bruno.accent, lineWidth: 3)
                        .opacity(isFocused && !isSelected ? 1 : 0)
                }
                .scaleEffect(isFocused ? 1.05 : 1.0)
                // Animate scale + ring opacity + fill together off the single focus signal.
                .animation(.easeOut(duration: 0.15), value: isFocused)
        }
        // Chrome-less style (like the hero button): the focus cursor is OUR accent capsule, so suppress
        // the system's default rounded-rect button highlight — it was a larger, offset shape that
        // didn't match the pill (the geometry mismatch).
        .buttonStyle(BrunoSelectorButtonStyle())
        .focused($isFocused)
        .onChange(of: isFocused) { _, focused in
            if focused, selectsOnFocus { action() }
        }
    }
}

// MARK: - BrunoSelectorButtonStyle

private struct BrunoSelectorButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
