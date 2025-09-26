//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Get
import JellyfinAPI
import UIKit

// TODO: preload chapter images
//       - somehow tell player if there are no images
//         and don't present popup overlay
// TODO: just use Nuke image pipeline

class ChapterPreviewImageProvider: PreviewImageProvider {

    let chapters: [ChapterInfo.FullInfo]

    @MainActor
    private var images: [Int: UIImage] = [:]
    @MainActor
    private var imageTasks: [Int: Task<UIImage?, Never>] = [:]

    init(chapters: [ChapterInfo.FullInfo]) {
        self.chapters = chapters
    }

    func imageIndex(for seconds: Duration) -> Int? {
        guard let currentChapterIndex = chapters
            .firstIndex(where: {
                guard let startSeconds = $0.chapterInfo.startSeconds else { return false }
                return startSeconds > seconds
            }
            ) else { return nil }

        return max(0, currentChapterIndex - 1)
    }

    @MainActor
    func image(for seconds: Duration) async -> UIImage? {
        guard let chapterIndex = imageIndex(for: seconds) else { return nil }

        if let image = images[chapterIndex] {
            return image
        }

        if let task = imageTasks[chapterIndex] {
            return await task.value
        }

        let newTask = Task<UIImage?, Never> {
            let client = Container.shared.currentUserSession()!.client

            guard let chapterInfo = chapters[safe: chapterIndex], let imageUrl = chapterInfo.imageSource.url else { return nil }
            let request: Request<Data> = .init(url: imageUrl)

            guard let response = try? await client.send(request) else { return nil }
            guard let image = UIImage(data: response.value) else { return nil }

            return image
        }

        imageTasks[chapterIndex] = newTask
        return await newTask.value
    }
}
