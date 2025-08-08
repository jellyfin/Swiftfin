//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import Logging

final class DownloadURLBuilder: DownloadURLBuilding {

    private let logger = Logger.swiftfin()

    init() {}

    // MARK: - Public Interface

    func mediaURL(
        itemId: String,
        quality: DownloadQuality,
        mediaSourceId: String?,
        container: String,
        isStatic: Bool,
        allowVideoStreamCopy: Bool,
        allowAudioStreamCopy: Bool,
        deviceId: String?,
        deviceProfileId: String?
    ) -> URL? {
        switch quality {
        case .original:
            return constructDownloadURL(
                itemId: itemId,
                mediaSourceId: mediaSourceId,
                container: container,
                isStatic: isStatic,
                allowVideoStreamCopy: allowVideoStreamCopy,
                allowAudioStreamCopy: allowAudioStreamCopy,
                deviceId: deviceId,
                deviceProfileId: deviceProfileId
            )
        case .high:
            return constructTranscodingDownloadURL(
                itemId: itemId,
                transcodingParams: .highQuality,
                mediaSourceId: mediaSourceId,
                container: container,
                allowVideoStreamCopy: allowVideoStreamCopy,
                allowAudioStreamCopy: allowAudioStreamCopy,
                deviceId: deviceId,
                deviceProfileId: deviceProfileId
            )
        case .medium:
            return constructTranscodingDownloadURL(
                itemId: itemId,
                transcodingParams: .mediumQuality,
                mediaSourceId: mediaSourceId,
                container: container,
                allowVideoStreamCopy: allowVideoStreamCopy,
                allowAudioStreamCopy: allowAudioStreamCopy,
                deviceId: deviceId,
                deviceProfileId: deviceProfileId
            )
        case .low:
            return constructTranscodingDownloadURL(
                itemId: itemId,
                transcodingParams: .lowQuality,
                mediaSourceId: mediaSourceId,
                container: container,
                allowVideoStreamCopy: allowVideoStreamCopy,
                allowAudioStreamCopy: allowAudioStreamCopy,
                deviceId: deviceId,
                deviceProfileId: deviceProfileId
            )
        case let .custom(params):
            return constructTranscodingDownloadURL(
                itemId: itemId,
                transcodingParams: params,
                mediaSourceId: mediaSourceId,
                container: container,
                allowVideoStreamCopy: allowVideoStreamCopy,
                allowAudioStreamCopy: allowAudioStreamCopy,
                deviceId: deviceId,
                deviceProfileId: deviceProfileId
            )
        }
    }

    func imageURL(for item: BaseItemDto, type: DownloadJobType) -> URL? {
        let imageURL: URL?

        switch type {
        case .backdropImage:
            switch item.type {
            case .movie, .series:
                imageURL = item.imageSource(.backdrop, maxWidth: 600).url
            case .episode:
                imageURL = item.imageSource(.primary, maxWidth: 600).url
            default:
                return nil
            }
        case .primaryImage:
            switch item.type {
            case .movie, .series:
                imageURL = item.imageSource(.primary, maxWidth: 300).url
            default:
                return nil
            }
        default:
            return nil
        }

        return imageURL
    }

    // MARK: - Private URL Construction

    private func constructDownloadURL(
        itemId: String,
        mediaSourceId: String?,
        container: String,
        isStatic: Bool,
        allowVideoStreamCopy: Bool,
        allowAudioStreamCopy: Bool,
        deviceId: String?,
        deviceProfileId: String?
    ) -> URL? {
        // Input validation
        guard !itemId.isEmpty, !container.isEmpty else {
            logger.error("Invalid parameters: itemId and container cannot be empty")
            return nil
        }

        guard let userSession = Container.shared.currentUserSession() else {
            logger.error("No user session available for download URL construction")
            return nil
        }

        // Construct the download request with enhanced parameters
        var queryItems: [URLQueryItem] = []

        if let mediaSourceId = mediaSourceId {
            queryItems.append(URLQueryItem(name: "MediaSourceId", value: mediaSourceId))
        }

        queryItems.append(URLQueryItem(name: "Container", value: container))
        queryItems.append(URLQueryItem(name: "Static", value: isStatic.description))
        queryItems.append(URLQueryItem(name: "AllowVideoStreamCopy", value: allowVideoStreamCopy.description))
        queryItems.append(URLQueryItem(name: "AllowAudioStreamCopy", value: allowAudioStreamCopy.description))

        if let deviceId = deviceId {
            queryItems.append(URLQueryItem(name: "DeviceId", value: deviceId))
        }

        if let deviceProfileId = deviceProfileId {
            queryItems.append(URLQueryItem(name: "DeviceProfileId", value: deviceProfileId))
        }

        // Build the URL path
        let path = "/Items/\(itemId)/Download"

        guard let baseURL = userSession.client.fullURL(with: path) else { return nil }
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }

        components.queryItems = queryItems

        // Add API key to query if needed
        if let accessToken = userSession.client.accessToken {
            components.queryItems?.append(URLQueryItem(name: "api_key", value: accessToken))
        }

        return components.url
    }

    private func constructTranscodingDownloadURL(
        itemId: String,
        transcodingParams: TranscodingParameters,
        mediaSourceId: String?,
        container: String,
        allowVideoStreamCopy: Bool,
        allowAudioStreamCopy: Bool,
        deviceId: String?,
        deviceProfileId: String?
    ) -> URL? {
        guard let userSession = Container.shared.currentUserSession() else { return nil }
        let path = "/Items/\(itemId)/Download"
        guard let baseURL = userSession.client.fullURL(with: path),
              var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        else { return nil }

        var queryItems: [URLQueryItem] = []
        // Force transcoding
        queryItems.append(URLQueryItem(name: "Static", value: "false"))
        if let source = mediaSourceId {
            queryItems.append(URLQueryItem(name: "MediaSourceId", value: source))
        }
        queryItems.append(URLQueryItem(name: "Container", value: container))
        queryItems.append(URLQueryItem(name: "AllowVideoStreamCopy", value: allowVideoStreamCopy.description))
        queryItems.append(URLQueryItem(name: "AllowAudioStreamCopy", value: allowAudioStreamCopy.description))

        if let maxWidth = transcodingParams.maxWidth {
            queryItems.append(URLQueryItem(name: "maxWidth", value: String(maxWidth)))
        }
        if let maxHeight = transcodingParams.maxHeight {
            queryItems.append(URLQueryItem(name: "maxHeight", value: String(maxHeight)))
        }
        if let vbr = transcodingParams.videoBitRate {
            queryItems.append(URLQueryItem(name: "videoBitRate", value: String(vbr)))
        }
        if let abr = transcodingParams.audioBitRate {
            queryItems.append(URLQueryItem(name: "audioBitRate", value: String(abr)))
        }
        queryItems.append(URLQueryItem(name: "enableAutoStreamCopy", value: transcodingParams.enableAutoStreamCopy.description))

        if let deviceId = deviceId {
            queryItems.append(URLQueryItem(name: "DeviceId", value: deviceId))
        }
        if let deviceProfileId = deviceProfileId {
            queryItems.append(URLQueryItem(name: "DeviceProfileId", value: deviceProfileId))
        }

        components.queryItems = queryItems
        if let token = userSession.client.accessToken {
            components.queryItems?.append(URLQueryItem(name: "api_key", value: token))
        }

        return components.url
    }
}
