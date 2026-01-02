//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct JumpIntervalPicker: View {

    @State
    private var customSeconds: Int = 0
    @State
    private var isPresentingCustomInterval = false

    private let title: String
    private let selection: Binding<MediaJumpInterval>

    init(_ title: String, selection: Binding<MediaJumpInterval>) {
        self.title = title
        self.selection = selection
    }

    @ViewBuilder
    private var picker: some View {
        if #available(iOS 18.0, tvOS 18.0, *) {
            Picker(
                title,
                selection: selection
                    .map(
                        getter: {
                            if case .custom = $0 { .zero } else { $0.rawValue }
                        },
                        setter: {
                            MediaJumpInterval(rawValue: $0)
                        }
                    )
            ) {
                ForEach(MediaJumpInterval.allCases, id: \.hashValue) { interval in
                    Text(interval.rawValue, format: .minuteSecondsNarrow)
                        .tag(interval.rawValue)
                }

                Divider()

                Text(L10n.custom)
                    .tag(Duration.zero)
            } currentValueLabel: {
                Text(selection.wrappedValue.rawValue, format: .minuteSecondsNarrow)
            }
        } else {
            Picker(
                title,
                selection: selection
                    .map(
                        getter: {
                            if case .custom = $0 { .zero } else { $0.rawValue }
                        },
                        setter: {
                            MediaJumpInterval(rawValue: $0)
                        }
                    )
            ) {
                ForEach(MediaJumpInterval.allCases, id: \.hashValue) { interval in
                    Text(interval.rawValue, format: .minuteSecondsNarrow)
                        .tag(interval.rawValue)
                }

                Divider()

                Text(L10n.custom)
                    .tag(Duration.zero)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        #if os(tvOS)
        ListRowMenu(title, subtitle: Text(selection.wrappedValue.rawValue, format: .minuteSecondsNarrow)) {
            picker
        }
        #else
        picker
        #endif
    }

    var body: some View {
        content
            .backport
            .onChange(of: selection.wrappedValue) { oldValue, newValue in
                if case let .custom(interval) = newValue {
                    if interval == .zero {
                        customSeconds = Int(oldValue.rawValue.seconds)
                        selection.wrappedValue = .init(rawValue: .seconds(customSeconds))
                        isPresentingCustomInterval = true
                    } else {
                        if let matchingStatic = MediaJumpInterval.allCases.first(where: { $0.rawValue == interval }) {
                            selection.wrappedValue = matchingStatic
                        }
                    }
                }
            }
            .alert(L10n.jump, isPresented: $isPresentingCustomInterval) {
                TextField(L10n.duration, value: $customSeconds.clamp(min: 1, max: 600), format: .number)
                    .keyboardType(.numberPad)

                Button(L10n.ok) {
                    selection.wrappedValue = .custom(interval: Duration.seconds(customSeconds))
                }
            } message: {
                Text(L10n.customJumpIntervalDescription)
            }
    }
}
