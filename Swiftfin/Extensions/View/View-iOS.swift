//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Mantis
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

extension View {

    /// - Important: This does nothing on iOS.
    @ContentBuilder
    func focusSection() -> some View {
        self
    }

    @ContentBuilder
    func navigationBarFilterDrawer(
        viewModel: FilterViewModel,
        types: [ItemFilterType]
    ) -> some View {
        modifier(
            NavigationBarFilterDrawerModifier(
                viewModel: viewModel,
                types: types
            )
        )
    }

    @ContentBuilder
    func navigationBarCloseButton(
        disabled: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View {
        modifier(
            NavigationBarCloseButtonModifier(
                disabled: disabled,
                action: action
            )
        )
    }

    @ContentBuilder
    func navigationBarMenuButton(
        isLoading: Bool = false,
        isHidden: Bool = false,
        @ContentBuilder
        _ items: @escaping () -> some View
    ) -> some View {
        modifier(
            NavigationBarMenuButtonModifier(
                isLoading: isLoading,
                isHidden: isHidden,
                menuContent: items
            )
        )
    }

    @ContentBuilder
    func listRowCornerRadius(_ radius: CGFloat) -> some View {
        introspect(.listCell, on: .iOS(.v18...)) { cell in
            if #available(iOS 26, *) {
                cell.cornerConfiguration = .uniformCorners(radius: .fixed(radius))
            } else {
                cell.layer.cornerRadius = radius
            }
        }
    }

    /// Photo Picker with cropping after selection
    @ContentBuilder
    func photoPicker(
        isPresented: Binding<Bool>,
        isSaving: Bool,
        cropShape: Mantis.CropShapeType = .rect,
        presetRatio: Mantis.PresetFixedRatioType = .canUseMultiplePresetFixedRatio(defaultRatio: 0),
        onSave: @escaping (UIImage) -> Void
    ) -> some View {
        modifier(
            PhotoPickerModifier(
                isPresented: isPresented,
                isSaving: isSaving,
                cropShape: cropShape,
                presetRatio: presetRatio,
                onSave: onSave
            )
        )
    }
}
