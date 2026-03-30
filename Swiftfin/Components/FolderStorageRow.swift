//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct FolderStorageRow: View {

    @Default(.accentColor)
    private var accentColor

    private let title: String
    private let folder: FolderStorageDto

    init(_ title: String, folder: FolderStorageDto) {
        self.title = title
        self.folder = folder
    }

    private var usedSpace: Int {
        folder.usedSpace ?? 0
    }

    private var freeSpace: Int {
        folder.freeSpace ?? 0
    }

    private var totalSpace: Int {
        usedSpace + freeSpace
    }

    private var usagePercentage: Double {
        clamp(Double(usedSpace) / Double(totalSpace), min: 0, max: 1)
    }

    private var ratio: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(.primary)

            if let path = folder.path {
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            ProgressView(value: usagePercentage)
                .progressViewStyle(.playback)
                .frame(height: 5)
                .foregroundStyle(accentColor)

            HStack {
                Text(usedSpace.formatted(.byteCount(style: .binary)))
                Spacer()
                Text(totalSpace.formatted(.byteCount(style: .binary)))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
    }
}
