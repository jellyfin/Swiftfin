//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum DownloadButtonTaskState {
    case ready
    case downloading
    case paused
    case completed
}

struct DownloadActionButtonWithProgress: View {
    let state: DownloadButtonTaskState
    let progress: Double

    var body: some View {
        Button {
            // onSelect(downloadTask)
        } label: {
            if state == .downloading {
                progressIcon()
            } else if state == .paused {
                progressIcon(iconName: "chevron.right.2", iconColor: .orange)

            } else {
                Image(systemName: iconName(for: state))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(iconColor(for: state))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Progress Icon

    private func progressIcon(iconName: String = "arrow.down", iconColor: Color = .accentColor) -> some View {
        ZStack {
            // Background circle (full, gray)
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)

            // Foreground progress (primary color)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    iconColor,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Center icon
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .bold(true)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(iconColor)
        }
        .frame(width: 24, height: 24)
    }

    // MARK: - Icon logic

    private func iconName(for state: DownloadButtonTaskState) -> String {
        switch state {
        case .completed:
            return "checkmark.circle.fill"
        case .paused:
            return "pause.circle"
        case .ready:
            return "arrow.down.circle"
        case .downloading:
            return "arrow.down" // Not used, handled by progressIcon
        }
    }

    private func iconColor(for state: DownloadButtonTaskState) -> Color {
        switch state {
        case .completed:
            return .green
        default:
            return .accentColor
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 20) {
        DownloadActionButtonWithProgress(state: .ready, progress: 0.0)
        DownloadActionButtonWithProgress(state: .downloading, progress: 0.6)
        DownloadActionButtonWithProgress(state: .paused, progress: 0.3)
        DownloadActionButtonWithProgress(state: .completed, progress: 1.0)
    }
}
