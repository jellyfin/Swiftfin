//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Files
import SwiftUI

struct FileTextView: UIViewRepresentable {

    let file: File

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        DispatchQueue.main.async { [weak textView] in
            if let fileContents = try? file.readAsString() {
                textView?.text = fileContents
            } else {
                textView?.text = "Unable to read file"
            }
        }

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {}
}
