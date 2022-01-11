//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import UIKit

// 001fC^ = dark grey plain blurhash

public extension BaseItemDto {
	// MARK: Images

	func getSeriesBackdropImageBlurHash() -> String {
		let imgURL = getSeriesBackdropImage(maxWidth: 1)
		guard let imgTag = imgURL.queryParameters?["tag"],
		      let hash = imageBlurHashes?.backdrop?[imgTag]
		else {
			return "001fC^"
		}

		return hash
	}

	func getSeriesPrimaryImageBlurHash() -> String {
		let imgURL = getSeriesPrimaryImage(maxWidth: 1)
		guard let imgTag = imgURL.queryParameters?["tag"],
		      let hash = imageBlurHashes?.primary?[imgTag]
		else {
			return "001fC^"
		}

		return hash
	}

	func getPrimaryImageBlurHash() -> String {
		let imgURL = getPrimaryImage(maxWidth: 1)
		guard let imgTag = imgURL.queryParameters?["tag"],
		      let hash = imageBlurHashes?.primary?[imgTag]
		else {
			return "001fC^"
		}

		return hash
	}

	func getBackdropImageBlurHash() -> String {
		let imgURL = getBackdropImage(maxWidth: 1)
		guard let imgTag = imgURL.queryParameters?["tag"] else {
			return "001fC^"
		}

		if imgURL.queryParameters?[ImageType.backdrop.rawValue] == nil {
			return imageBlurHashes?.backdrop?[imgTag] ?? "001fC^"
		} else {
			return imageBlurHashes?.primary?[imgTag] ?? "001fC^"
		}
	}

	func getBackdropImage(maxWidth: Int) -> URL {
		var imageType = ImageType.backdrop
		var imageTag: String?
		var imageItemId = id ?? ""

		if primaryImageAspectRatio ?? 0.0 < 1.0 {
			if !(backdropImageTags?.isEmpty ?? true) {
				imageTag = backdropImageTags?.first
			}
		} else {
			imageType = .primary
			imageTag = imageTags?[ImageType.primary.rawValue] ?? ""
		}

		if imageTag == nil || imageItemId.isEmpty {
			if !(parentBackdropImageTags?.isEmpty ?? true) {
				imageTag = parentBackdropImageTags?.first
				imageItemId = parentBackdropItemId ?? ""
			}
		}

		let x = UIScreen.main.nativeScale * CGFloat(maxWidth)

		let urlString = ImageAPI.getItemImageWithRequestBuilder(itemId: imageItemId,
		                                                        imageType: imageType,
		                                                        maxWidth: Int(x),
		                                                        quality: 96,
		                                                        tag: imageTag).URLString
		return URL(string: urlString)!
	}

	func getEpisodeLocator() -> String? {
		if let seasonNo = parentIndexNumber, let episodeNo = indexNumber {
			return L10n.seasonAndEpisode(String(seasonNo), String(episodeNo))
		}
		return nil
	}

	func getSeriesBackdropImage(maxWidth: Int) -> URL {
		let x = UIScreen.main.nativeScale * CGFloat(maxWidth)
		let urlString = ImageAPI.getItemImageWithRequestBuilder(itemId: parentBackdropItemId ?? "",
		                                                        imageType: .backdrop,
		                                                        maxWidth: Int(x),
		                                                        quality: 96,
		                                                        tag: parentBackdropImageTags?.first).URLString
		return URL(string: urlString)!
	}

	func getSeriesPrimaryImage(maxWidth: Int) -> URL {
		let x = UIScreen.main.nativeScale * CGFloat(maxWidth)
		let urlString = ImageAPI.getItemImageWithRequestBuilder(itemId: seriesId ?? "",
		                                                        imageType: .primary,
		                                                        maxWidth: Int(x),
		                                                        quality: 96,
		                                                        tag: seriesPrimaryImageTag).URLString
		return URL(string: urlString)!
	}

	func getPrimaryImage(maxWidth: Int) -> URL {
		let imageType = ImageType.primary
		var imageTag = imageTags?[ImageType.primary.rawValue] ?? ""
		var imageItemId = id ?? ""

		if imageTag.isEmpty || imageItemId.isEmpty {
			imageTag = seriesPrimaryImageTag ?? ""
			imageItemId = seriesId ?? ""
		}

		let x = UIScreen.main.nativeScale * CGFloat(maxWidth)

		let urlString = ImageAPI.getItemImageWithRequestBuilder(itemId: imageItemId,
		                                                        imageType: imageType,
		                                                        maxWidth: Int(x),
		                                                        quality: 96,
		                                                        tag: imageTag).URLString
		return URL(string: urlString)!
	}

	// MARK: Calculations

	func getItemRuntime() -> String? {
		let timeHMSFormatter: DateComponentsFormatter = {
			let formatter = DateComponentsFormatter()
			formatter.unitsStyle = .abbreviated
			formatter.allowedUnits = [.hour, .minute]
			return formatter
		}()

		guard let runTimeTicks = runTimeTicks,
		      let text = timeHMSFormatter.string(from: Double(runTimeTicks / 10_000_000)) else { return nil }

		return text
	}

	func getItemProgressString() -> String? {
		if userData?.playbackPositionTicks == nil || userData?.playbackPositionTicks == 0 {
			return nil
		}

		let remainingSecs = ((runTimeTicks ?? 0) - (userData?.playbackPositionTicks ?? 0)) / 10_000_000
		let proghours = Int(remainingSecs / 3600)
		let progminutes = Int((Int(remainingSecs) - (proghours * 3600)) / 60)
		if proghours != 0 {
			return "\(proghours)h \(String(progminutes).leftPad(toWidth: 2, withString: "0"))m"
		} else {
			return "\(String(progminutes))m"
		}
	}

	func getLiveStartTimeString(formatter: DateFormatter) -> String {
		if let startDate = self.startDate {
			return formatter.string(from: startDate)
		}
		return " "
	}

	func getLiveEndTimeString(formatter: DateFormatter) -> String {
		if let endDate = self.endDate {
			return formatter.string(from: endDate)
		}
		return " "
	}

	func getLiveProgressPercentage() -> Double {
		if let startDate = self.startDate,
		   let endDate = self.endDate
		{
			let start = startDate.timeIntervalSinceReferenceDate
			let end = endDate.timeIntervalSinceReferenceDate
			let now = Date().timeIntervalSinceReferenceDate
			let length = end - start
			let progress = now - start
			return progress / length
		}
		return 0
	}

	// MARK: ItemType

	enum ItemType: String {
		case movie = "Movie"
		case season = "Season"
		case episode = "Episode"
		case series = "Series"
		case boxset = "BoxSet"

		case unknown

		var showDetails: Bool {
			switch self {
			case .season, .series:
				return false
			default:
				return true
			}
		}
	}

	var itemType: ItemType {
		guard let originalType = type, let knownType = ItemType(rawValue: originalType) else { return .unknown }
		return knownType
	}

	// MARK: PortraitHeaderViewURL

	func portraitHeaderViewURL(maxWidth: Int) -> URL {
		switch itemType {
		case .movie, .season, .series, .boxset:
			return getPrimaryImage(maxWidth: maxWidth)
		case .episode:
			return getSeriesPrimaryImage(maxWidth: maxWidth)
		case .unknown:
			return getPrimaryImage(maxWidth: maxWidth)
		}
	}

	// MARK: ItemDetail

	struct ItemDetail {
		let title: String
		let content: String
	}

	func createInformationItems() -> [ItemDetail] {
		var informationItems: [ItemDetail] = []

		if let productionYear = productionYear {
			informationItems.append(ItemDetail(title: L10n.released, content: "\(productionYear)"))
		}

		if let rating = officialRating {
			informationItems.append(ItemDetail(title: L10n.rated, content: "\(rating)"))
		}

		if let runtime = getItemRuntime() {
			informationItems.append(ItemDetail(title: L10n.runtime, content: runtime))
		}

		return informationItems
	}

	func createMediaItems() -> [ItemDetail] {
		var mediaItems: [ItemDetail] = []

		if let container = container {
			let containerList = container.split(separator: ",").joined(separator: ", ")
			mediaItems.append(ItemDetail(title: L10n.containers, content: containerList))
		}

		if let mediaStreams = mediaStreams {
			let audioStreams = mediaStreams.filter { $0.type == .audio }
			let subtitleStreams = mediaStreams.filter { $0.type == .subtitle }

			if !audioStreams.isEmpty {
				let audioList = audioStreams.compactMap { "\($0.displayTitle ?? L10n.noTitle) (\($0.codec ?? L10n.noCodec))" }
					.joined(separator: ", ")
				mediaItems.append(ItemDetail(title: L10n.audio, content: audioList))
			}

			if !subtitleStreams.isEmpty {
				let subtitleList = subtitleStreams.compactMap { "\($0.displayTitle ?? L10n.noTitle) (\($0.codec ?? L10n.noCodec))" }
					.joined(separator: ", ")
				mediaItems.append(ItemDetail(title: L10n.subtitles, content: subtitleList))
			}
		}

		return mediaItems
	}

	// MARK: Missing and Unaired

	var missing: Bool {
		locationType == .virtual
	}

	var unaired: Bool {
		if let premierDate = premiereDate {
			return premierDate > Date()
		} else {
			return true
		}
	}

	var airDateLabel: String? {
		guard let premiereDateFormatted = premiereDateFormatted else { return nil }
		return L10n.airWithDate(premiereDateFormatted)
	}

	var premiereDateFormatted: String? {
		guard let premiereDate = premiereDate else { return nil }

		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		return dateFormatter.string(from: premiereDate)
	}
}
