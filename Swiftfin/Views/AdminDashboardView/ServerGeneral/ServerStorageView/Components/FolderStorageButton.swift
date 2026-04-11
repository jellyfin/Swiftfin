//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Engine
import JellyfinAPI
import SwiftUI

extension ServerPathsView {

    struct FolderStorageButton: View {

        @Default(.accentColor)
        private var accentColor

        private let title: String
        private let folder: FolderStorageDto
        private let path: Binding<String>?
        private let onSave: (() -> Void)?

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

        var body: some View {
            if let path, let onSave {
                StateAdapter(initialValue: false) { isPresented in
                    ChevronButton {
                        isPresented.wrappedValue = true
                    } label: {
                        LabeledContent {
                            EmptyView()
                        } label: {
                            content
                        }
                    }
                    .alert(
                        title,
                        isPresented: isPresented
                    ) {
                        TextField(title, text: path)

                        Button(L10n.cancel, role: .cancel) {}

                        Button(L10n.save) {
                            onSave()
                        }
                    }
                }
            } else {
                content
            }
        }

        private var content: some View {
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
}

extension ServerPathsView.FolderStorageButton {

    /// Editable folder with a path binding and save action
    init(
        _ title: String,
        folder: FolderStorageDto,
        path: Binding<String>,
        onSave: @escaping () -> Void
    ) {
        self.title = title
        self.folder = folder
        self.path = path
        self.onSave = onSave
    }

    /// Read-only folder display
    init(_ title: String, folder: FolderStorageDto) {
        self.title = title
        self.folder = folder
        self.path = nil
        self.onSave = nil
    }
}
