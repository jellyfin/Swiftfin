//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

protocol PlatformForm: PlatformView {

    associatedtype Content: View

    var imageView: FormImage? { get }

    @ViewBuilder
    @MainActor
    var formView: Content { get }
}

extension PlatformForm {

    var imageView: FormImage? { nil }

    @MainActor
    var iOSView: some View {
        formView
            .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    var tvOSView: some View {
        HStack {
            if let imageView {
                imageView
                    .frame(maxWidth: .infinity)
            }

            formView
                .padding(.top)
            #if os(tvOS)
                .scrollClipDisabled()
            #endif
        }
    }
}
