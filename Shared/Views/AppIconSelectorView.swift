//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct AppIconSelectorView: View {

    @State
    private var currentAppIcon = AppIcon.resolve(alternateIconName: UIApplication.shared.alternateIconName)

    @MainActor
    private func select(icon: AppIcon) async {
        let previousAppIcon = currentAppIcon
        currentAppIcon = icon

        do {
            try await UIApplication.shared.setAlternateIconName(icon.alternateIconName)
        } catch {
            currentAppIcon = previousAppIcon
        }
    }

    var body: some View {
        Form {
            ForEach(AppIcon.allCases) { icon in
                AppIconRow(icon: icon) {
                    Task {
                        await select(icon: icon)
                    }
                }
                .isSelected(icon == currentAppIcon)
            }
        } image: {
            Image(currentAppIcon.iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 400)
                .cornerRadius(48)
                .subtleShadow()
        }
        .navigationTitle(L10n.appIcon.localizedCapitalized)
    }
}

extension AppIconSelectorView {

    struct AppIconRow: View {

        @AdaptiveLayout
        private var viewLayout

        let icon: AppIcon
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack {
                    Image(icon.iconName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: viewLayout.value(standard: 60, large: 150),
                            height: viewLayout.value(standard: 60, large: 90)
                        )
                        .cornerRadius(viewLayout.value(standard: 12, large: 18))
                        .subtleShadow()

                    Text(icon.displayTitle)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ListRowCheckbox()
                        .isEditing(true)
                }
            }
            .foregroundStyle(.primary, .secondary)
        }
    }
}
