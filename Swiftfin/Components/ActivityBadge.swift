//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ActivityBadge: View {

    let value: Int

    private let size = 16.0
    private let x = 20.0
    private let y = 0.0

    // MARK: - Body

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.accentColor)
                .frame(width: size * widthMultplier(), height: size, alignment: .topTrailing)
                .overlay {
                    Capsule()
                        .stroke(Color.systemBackground, lineWidth: 1.5)
                }
                .position(x: x, y: y)

            if hasTwoOrLessDigits() {
                Text("\(value)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .position(x: x, y: y)
            } else {
                Text("99+")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .frame(width: size * widthMultplier(), height: size, alignment: .center)
                    .position(x: x, y: y)
            }
        }
        .opacity(value == 0 ? 0 : 1)
    }

    // MARK: - Check Number of Digits

    func hasTwoOrLessDigits() -> Bool {
        value < 100
    }

    // MARK: - Get Badge Width

    func widthMultplier() -> Double {
        if value < 10 {
            return 1.0
        } else if value < 100 {
            return 1.5
        } else {
            return 2.0
        }
    }
}
