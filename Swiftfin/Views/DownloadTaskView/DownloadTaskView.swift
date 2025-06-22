//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct DownloadTaskView: View {

    @Router
    private var router

    @ObservedObject
    var downloadTask: DownloadTask

    var body: some View {
        ScrollView(showsIndicators: false) {
            ContentView(downloadTask: downloadTask)
        }
        .navigationBarCloseButton {
            router.dismiss()
        }
    }
}
