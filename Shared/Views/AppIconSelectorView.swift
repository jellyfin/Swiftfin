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
    private var currentAppIcon = AppIcon(alternateIconName: UIApplication.shared.alternateIconName)
    @State
    private var currentBackground = AppIconBackground(alternateIconName: UIApplication.shared.alternateIconName)

    #if os(tvOS)
    private let size = CGSize(width: 150, height: 90)
    private let darkColor = Color(red: 0, green: 0.055, blue: 0.192)
    #else
    private let size = CGSize(width: 60, height: 60)
    private let darkColor = Color.black
    #endif

    var body: some View {
        Form(image: .jellyfinBlobBlue) {
            #if os(tvOS)
            ListRowMenu(L10n.appearance, subtitle: currentBackground.displayTitle) {
                Picker(L10n.appearance, selection: $currentBackground)
            }
            #endif

            Section {
                ForEach(AppIcon.allCases) { icon in
                    Button {
                        currentAppIcon = icon
                    } label: {
                        HStack {
                            Image("AppIcon-glyph-\(icon.rawValue)")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: size.width, height: size.height)
                                .background(currentBackground == .dark ? darkColor : .white)
                                .cornerRadius(size.height / 5)
                                .subtleShadow()

                            Text(icon.displayTitle)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ListRowCheckbox()
                                .isEditing(true)
                                .isSelected(icon == currentAppIcon)
                        }
                    }
                    .foregroundStyle(.primary, .secondary)
                }
            }
        }
        .navigationTitle(L10n.appIcon.localizedCapitalized)
        .onChange(of: currentAppIcon.alternateIconName(background: currentBackground)) { _, newValue in
            Task {
                do {
                    try await UIApplication.shared.setAlternateIconName(newValue)
                } catch {
                    currentAppIcon = AppIcon(alternateIconName: UIApplication.shared.alternateIconName)
                    currentBackground = AppIconBackground(alternateIconName: UIApplication.shared.alternateIconName)
                }
            }
        }
    }
}
