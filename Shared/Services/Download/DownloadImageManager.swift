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

        // Download backdrop image
        if let backdropURL = urlBuilder.imageURL(for: task.item, type: .backdropImage) {
            group.enter()
            downloadSingleImage(url: backdropURL, for: task, type: .backdropImage) { result in
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

        // Download primary image
        if let primaryURL = urlBuilder.imageURL(for: task.item, type: .primaryImage) {
            group.enter()
            downloadSingleImage(url: primaryURL, for: task, type: .primaryImage) { result in
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
                    jobType: type
                )

                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
