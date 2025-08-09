//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Logging

final class DownloadImageManager: DownloadImageManaging {

    private let logger = Logger.swiftfin()
    private let urlBuilder: DownloadURLBuilding
    private let fileService: DownloadFileServicing

    init(urlBuilder: DownloadURLBuilding, fileService: DownloadFileServicing) {
        self.urlBuilder = urlBuilder
        self.fileService = fileService
    }

    // MARK: - Public Interface

    func downloadImages(for task: DownloadTask, completion: @escaping (Result<Void, Error>) -> Void) {
        let group = DispatchGroup()
        var errors: [Error] = []

        // Download episode's own images
        if let backdropURL = urlBuilder.imageURL(for: task.item, type: .backdropImage),
           let itemID = task.item.id
        {
            let context: ImageDownloadContext
            switch task.item.type {
            case .movie:
                context = .movie(id: itemID)
            case .episode:
                context = .episode(id: itemID)
            default:
                context = .episode(id: itemID)
            }

            group.enter()
            downloadSingleImage(url: backdropURL, for: task, type: .backdropImage, context: context) { result in
                switch result {
                case .success:
                    self.logger.trace("Successfully downloaded backdrop image for: \(task.item.displayTitle)")
                case let .failure(error):
                    self.logger.warning("Failed to download backdrop image: \(error.localizedDescription)")
                    errors.append(error)
                }
                group.leave()
            }
        }
        if let primaryURL = urlBuilder.imageURL(for: task.item, type: .primaryImage),
           let itemID = task.item.id
        {
            let context: ImageDownloadContext
            switch task.item.type {
            case .movie:
                context = .movie(id: itemID)
            case .episode:
                context = .episode(id: itemID)
            default:
                context = .episode(id: itemID)
            }

            group.enter()
            downloadSingleImage(url: primaryURL, for: task, type: .primaryImage, context: context) { result in
                switch result {
                case .success:
                    self.logger.trace("Successfully downloaded primary image for: \(task.item.displayTitle)")
                case let .failure(error):
                    self.logger.warning("Failed to download primary image: \(error.localizedDescription)")
                    errors.append(error)
                }
                group.leave()
            }
        }

        // If the item is an episode, also download show and series images
        if task.item.type == .episode {
            // Download season's primary image (parent)
            if let seasonPrimaryURL = task.item.seasonImageURL(.primary), seasonPrimaryURL != urlBuilder.imageURL(
                for: task.item,
                type: .primaryImage
            ) {
                let seasonContext: ImageDownloadContext = {
                    if let seasonID = task.item.seasonID {
                        return .season(id: seasonID)
                    } else {
                        return .episode(id: task.item.id ?? "")
                    }
                }()

                group.enter()
                downloadSingleImage(url: seasonPrimaryURL, for: task, type: .primaryImage, context: seasonContext) { result in
                    switch result {
                    case .success:
                        self.logger.trace("Successfully downloaded season primary image for: \(task.item.displayTitle)")
                    case let .failure(error):
                        self.logger.warning("Failed to download season primary image: \(error.localizedDescription)")
                        errors.append(error)
                    }
                    group.leave()
                }
            }
            // Download series images (if available)
            if let seriesBackdropURL = task.item.seriesImageURL(.backdrop),
               let seriesID = task.item.seriesID
            {
                group.enter()
                downloadSingleImage(
                    url: seriesBackdropURL,
                    for: task,
                    type: .backdropImage,
                    context: .series(id: seriesID)
                ) { result in
                    switch result {
                    case .success:
                        self.logger.trace("Successfully downloaded series backdrop image for: \(task.item.displayTitle)")
                    case let .failure(error):
                        self.logger.warning("Failed to download series backdrop image: \(error.localizedDescription)")
                        errors.append(error)
                    }
                    group.leave()
                }
            }
            if let seriesPrimaryURL = task.item.seriesImageURL(.primary),
               let seriesID = task.item.seriesID
            {
                group.enter()
                downloadSingleImage(
                    url: seriesPrimaryURL,
                    for: task,
                    type: .primaryImage,
                    context: .series(id: seriesID)
                ) { result in
                    switch result {
                    case .success:
                        self.logger.trace("Successfully downloaded series primary image for: \(task.item.displayTitle)")
                    case let .failure(error):
                        self.logger.warning("Failed to download series primary image: \(error.localizedDescription)")
                        errors.append(error)
                    }
                    group.leave()
                }
            }
        }

        // Complete when all images are downloaded (or failed)
        group.notify(queue: .global(qos: .utility)) {
            if errors.isEmpty {
                completion(.success(()))
            } else {
                // For images, we don't fail the entire download if images fail
                // We just log the errors and continue
                self.logger.info("Some image downloads failed, but continuing with main download")
                completion(.success(()))
            }
        }
    }

    // MARK: - Private Helpers

    private func downloadSingleImage(
        url: URL,
        for task: DownloadTask,
        type: DownloadJobType,
        context: ImageDownloadContext,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let urlRequest = URLRequest(url: url)

        URLSession.shared.downloadTask(with: urlRequest) { [weak self] tempURL, response, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let tempURL = tempURL else {
                completion(.failure(NSError(
                    domain: "DownloadImageManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No temporary file location"]
                )))
                return
            }

            do {
                // Move the image file to its final destination
                guard let downloadFolder = task.item.downloadFolder else {
                    throw NSError(
                        domain: "DownloadImageManager",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "No download folder available"]
                    )
                }

                try self.fileService.moveImageFile(
                    from: tempURL,
                    to: downloadFolder,
                    for: task,
                    response: response,
                    jobType: type,
                    context: context
                )

                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
