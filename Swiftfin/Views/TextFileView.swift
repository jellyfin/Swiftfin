//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Files
import SwiftUI

struct TextFileView: View {

    @EnvironmentObject
    private var router: SettingsCoordinator.Router

    let file: File

    var body: some View {
        FileTextView(file: file)
            .navigationTitle(file.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        router.route(to: \.shareFile, file)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
    }
}
