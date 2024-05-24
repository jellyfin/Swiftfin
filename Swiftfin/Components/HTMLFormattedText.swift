//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct HTMLFormattedText: UIViewRepresentable {
    let text: String
    private let textView = UITextView()

    init(_ content: String) {
        self.text = content
    }

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UITextView {
        textView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width).isActive = true
        textView.isSelectable = false
        textView.isUserInteractionEnabled = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<Self>) {
        DispatchQueue.main.async {
            if let attributeText = self.converHTML(text: text) {
                textView.attributedText = attributeText
            } else {
                textView.text = ""
            }
        }
    }

    private func converHTML(text: String) -> NSAttributedString? {
        guard let data = text.data(using: .utf8) else {
            return nil
        }

        if let attributedString = try? NSMutableAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) {
            let range = NSRange(location: 0, length: attributedString.length)
            attributedString.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
                if let oldFont = value as? UIFont {
                    let fontSize = UIScreen.main.bounds.width * 0.05 // Adjust the multiplier as needed
                    let dynamicFont = UIFont.systemFont(ofSize: fontSize)
                    let newFont = oldFont.withSize(dynamicFont.pointSize)
                    attributedString.addAttributes([.font: newFont], range: range)
                }
            }
            return attributedString
        } else {
            return nil
        }
    }
}
