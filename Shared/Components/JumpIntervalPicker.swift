//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct JumpIntervalPicker: View {

    let title: String
    let selection: Binding<MediaJumpInterval>

    init(_ title: String, selection: Binding<MediaJumpInterval>) {
        self.title = title
        self.selection = selection
    }

    var body: some View {
        contentView
    }

    @ViewBuilder
    private var contentView: some View {
        #if os(tvOS)
        ListRowMenu(title, subtitle: Text(selection.wrappedValue.displayTitle)) {
            pickerView
        }
        #else
        pickerView
        #endif
    }

    @ViewBuilder
    private var pickerView: some View {
        Picker(
            title,
            selection: selection,
            currentValue: selection.wrappedValue.displayTitle,
            isCustom: { if case .custom = $0 { true } else { false } },
            customTag: .custom(interval: .zero),
            customDefault: { .custom(interval: $0.rawValue) },
            customDescription: L10n.customJumpIntervalDescription
        ) {
            ForEach(MediaJumpInterval.allCases, id: \.hashValue) { interval in
                Text(interval.displayTitle)
                    .tag(interval)
            }
        } customInput: { $value in
            TextField(L10n.duration, value: Binding(
                get: {
                    if case let .custom(interval) = value {
                        Int(interval.components.seconds)
                    } else {
                        Int(value.rawValue.components.seconds)
                    }
                },
                set: { seconds in
                    if let matching = MediaJumpInterval.allCases.first(where: { $0.rawValue == .seconds(seconds) }) {
                        value = matching
                    } else {
                        value = .custom(interval: .seconds(seconds))
                    }
                }
            ), format: .number)
                .keyboardType(.numberPad)
                .backport
                .onChange(of: value) { _, newValue in
                    if newValue.rawValue.components.seconds < 1 {
                        value = .custom(interval: .seconds(1))
                    }
                }
        }
    }
}
