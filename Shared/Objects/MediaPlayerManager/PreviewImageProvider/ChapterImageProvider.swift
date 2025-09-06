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

class ChapterImageProvider: PreviewImageProvider {

    let chapters: [ChapterInfo.FullInfo]

    @MainActor
    private var images: [Int: UIImage] = [:]
    @MainActor
    private var imageTasks: [Int: Task<UIImage?, Never>] = [:]

    init(chapters: [ChapterInfo.FullInfo]) {
        self.chapters = chapters
    }

    func imageIndex(for seconds: Duration) -> Int {
        chapters.firstIndex { $0.secondsRange.contains(seconds) } ?? 0
    }

    @MainActor
    func image(for seconds: Duration) async -> UIImage? {
        let chapterIndex = imageIndex(for: seconds)

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
