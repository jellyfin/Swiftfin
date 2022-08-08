//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import SwiftUI
import UIKit

struct BlurHashView: UIViewRepresentable {

    private let blurHash: String
    private let size: CGSize

    init(blurHash: String, size: CGSize = .Circle(radius: 12)) {
        self.blurHash = blurHash
        self.size = size
    }

    func makeUIView(context: Context) -> UIBlurHashView {
        UIBlurHashView(blurHash, size: size)
    }

    func updateUIView(_ uiView: UIBlurHashView, context: Context) {}
}

class UIBlurHashView: UIView {

    private let imageView: UIImageView

    init(_ blurHash: String, size: CGSize) {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        self.imageView = imageView

        super.init(frame: .zero)

        computeBlurHashImageAsync(blurHash: blurHash, size: size) { [weak self] blurImage in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.imageView.image = blurImage
                self.imageView.setNeedsDisplay()
            }
        }

        addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leftAnchor.constraint(equalTo: leftAnchor),
            imageView.rightAnchor.constraint(equalTo: rightAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func computeBlurHashImageAsync(blurHash: String, size: CGSize, _ completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let image = UIImage(blurHash: blurHash, size: size)
            completion(image)
        }
    }
}
