//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct JumpIntervalPicker: View {

    private let title: String

    @Binding
    private var selection: MediaJumpInterval

    @State
    private var showCustomInput = false
    @State
    private var customSeconds: Int = 10

    init(_ title: String, selection: Binding<MediaJumpInterval>) {
        self.title = title
        self._selection = selection
    }

    private var pickerLabel: String {
        if case let .custom(interval) = selection {
            return interval.formatted(.minuteSecondsNarrow)
        }
        return selection.rawValue.formatted(.minuteSecondsNarrow)
    }

    var body: some View {
        pickerView
            .alert(L10n.custom, isPresented: $showCustomInput) {
                TextField(L10n.duration, value: $customSeconds, format: .number)
                    .keyboardType(.numberPad)

                Button(L10n.save) {
                    selection = .custom(interval: .seconds(customSeconds))
                }
            } message: {
                Text(L10n.customJumpIntervalDescription)
            }
    }

    @ViewBuilder
    private var pickerView: some View {
        #if os(tvOS)
        ListRowMenu(title, subtitle: pickerLabel) {
            menuContent
        }
        #else
        HStack {
            Text(title)

            Spacer()

            Menu {
                menuContent
            } label: {
                HStack {
                    Text(pickerLabel)
                    Image(systemName: "chevron.up.chevron.down")
                }
                .foregroundStyle(Color.secondary)
            }
        }
        #endif
    }

    @ViewBuilder
    private var menuContent: some View {
        ForEach(MediaJumpInterval.supportedCases, id: \.rawValue) { interval in
            Button {
                selection = interval
            } label: {
                if selection == interval {
                    Label(interval.rawValue.formatted(.minuteSecondsNarrow), systemImage: "checkmark")
                } else {
                    Text(interval.rawValue.formatted(.minuteSecondsNarrow))
                }
            }
        }

        Divider()

        Button {
            if case let .custom(interval) = selection {
                customSeconds = Int(interval.components.seconds)
            }
            showCustomInput = true
        } label: {
            if case .custom = selection {
                Label(L10n.custom, systemImage: "checkmark")
            } else {
                Text(L10n.custom)
            }
        }
    }
}
